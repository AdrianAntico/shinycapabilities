# Workflow identity v2 deliberately does not change stable_hash(), which is also
# used by browser components and document formats unrelated to execution.
workflow_identity_value <- function(x) {
  if (is.environment(x) || is.function(x) || is.language(x) || isS4(x))
    stop("WORKFLOW_IDENTITY_UNSUPPORTED_TYPE", call. = FALSE)
  attrs <- attributes(x)
  n <- names(x)
  attrs$names <- NULL
  if (!is.null(n) && (anyNA(n) || any(!nzchar(n)) || anyDuplicated(n)))
    stop("WORKFLOW_IDENTITY_AMBIGUOUS_NAMES", call. = FALSE)
  # Attribute values (factor levels, dimensions, class, timezone, etc.) are
  # semantic. Only the names of attribute fields are unordered.
  a <- if (length(attrs)) workflow_identity_value(attrs) else NULL
  if (is.null(x)) return(list(type = "null"))
  if (is.list(x)) {
    values <- lapply(unname(x), workflow_identity_value)
    if (!is.null(n)) {
      o <- order(enc2utf8(n), method = "radix")
      return(list(type = "map", keys = enc2utf8(n[o]), values = values[o], attributes = a))
    }
    return(list(type = "sequence", values = values, attributes = a))
  }
  if (!is.atomic(x)) stop("WORKFLOW_IDENTITY_UNSUPPORTED_TYPE", call. = FALSE)
  attributes(x) <- NULL
  type <- typeof(x)
  # Workflow JSON has always treated integral doubles and integers alike.
  # Keep that choice explicit, without equating numbers with strings/logicals.
  if (type %in% c("integer", "double")) { type <- "number"; x <- as.double(x) }
  if (is.character(x)) x <- enc2utf8(x)
  if (!is.null(n)) {
    o <- order(enc2utf8(n), method = "radix")
    x <- x[o]; n <- enc2utf8(n[o])
  }
  list(type = type, names = n, values = x, attributes = a)
}

workflow_identity_hash <- function(x) {
  digest::digest(workflow_identity_value(x), algo = "sha256", serialize = TRUE,
    serializeVersion = 2L)
}

workflow_capability_identity <- function(capability) {
  list(capability_id = capability$id, capability_version = capability$version,
    implementation = capability$implementation_fingerprint,
    resource_hints = capability$resource_hints,
    execution_contract = capability$execution_contract)
}

legacy_node_signature <- function(node, capability, dependency_results = list()) {
  stable_hash(list(capability_id = capability$id, capability_version = capability$version,
    implementation = capability$implementation_fingerprint, config = node$config,
    dependencies = dependency_results))
}

workflow_cache_identity_current <- function(cache, signature) {
  if (is.null(cache) || !identical(cache$status, "succeeded")) return(FALSE)
  m <- attr(cache, "workflow_identity_migration", exact = TRUE)
  if (is.null(m)) return(identical(cache$signature, signature))
  tryCatch({
    if (!identical(m$schema_version, "workflow_identity_migration_v1") ||
        !identical(m$canonical_signature, signature) ||
        !identical(m$fingerprint, workflow_identity_hash(m[setdiff(names(m), "fingerprint")])))
      return(FALSE)
    if (!identical(cache$signature, m$legacy_signature)) return(FALSE)
    original <- cache; attr(original, "workflow_identity_migration") <- NULL
    identical(digest::digest(original, algo = "sha256"), m$legacy_cache_fingerprint)
  }, error = function(e) FALSE)
}

#' Migrate a verified legacy workflow cache without executing capabilities
#'
#' This is an explicit trust boundary: verify must authenticate the retained
#' execution witness against the application's immutable provenance authority.
#' It must not approve a witness merely because a package or constructor exists.
#' The witness contains graph, cache, capabilities (execution-time definitions),
#' authority (project/workflow/input revision and owners), and provenance.
#' Missing witnesses and changed semantics are refused; migration is atomic.
#' @param registry Current capability registry.
#' @param graph Current workflow graph.
#' @param witness Retained, attributable execution witness.
#' @param authority Current exact project/workflow/input/owner authority record.
#' @param verify Function authenticating the witness; must return TRUE.
#' @export
migrate_workflow_cache <- function(registry, graph, witness, authority, verify = NULL) {
  refuse <- function(code) list(ok = FALSE, code = code, cache = NULL)
  tryCatch({
    required <- c("graph", "cache", "capabilities", "authority", "provenance")
    scalar <- function(x) is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
    if (!is.list(witness) || !all(required %in% names(witness)) ||
        !is.list(authority) || !all(vapply(authority[c("project_id", "workflow_id", "input_revision")], scalar, logical(1))) ||
        !all(c("project_id", "workflow_id", "input_revision", "owners") %in% names(authority)) ||
        !is.list(authority$owners) || !length(authority$owners) ||
        !all(vapply(authority$owners, function(o) is.list(o) &&
          all(c("package", "version", "sha") %in% names(o)) &&
          all(vapply(o[c("package", "version", "sha")], scalar, logical(1))), logical(1))) ||
        !length(witness$provenance) ||
        !is.function(verify) || !isTRUE(verify(witness)))
      return(refuse("LEGACY_PROVENANCE_UNVERIFIABLE"))
    if (!identical(workflow_identity_hash(witness$authority), workflow_identity_hash(authority)))
      return(refuse("LEGACY_AUTHORITY_CHANGED"))
    old <- expand_workflow_composites(witness$graph)
    new <- expand_workflow_composites(graph)
    if (!identical(workflow_identity_hash(old), workflow_identity_hash(new)))
      return(refuse("LEGACY_INPUTS_CHANGED"))
    plan <- plan_workflow(registry, new)
    if (!isTRUE(plan$valid)) return(refuse("LEGACY_WORKFLOW_INCOMPATIBLE"))
    nodes <- setNames(old$nodes, vapply(old$nodes, `[[`, "", "id"))
    prior <- list(); successor <- witness$cache; audit <- list()
    for (step in plan$steps) {
      id <- step$node_id; node <- nodes[[id]]
      cap <- capability_registry_get(registry, node$capability_id)
      retained_cap <- witness$capabilities[[node$capability_id]]
      if (is.null(retained_cap) || !identical(
          workflow_identity_hash(workflow_capability_identity(retained_cap)),
          workflow_identity_hash(workflow_capability_identity(cap))))
        return(refuse("LEGACY_IMPLEMENTATION_CHANGED_OR_UNVERIFIABLE"))
      edges <- Filter(function(e) identical(e$target, id), old$edges)
      deps <- setNames(lapply(edges, function(e) prior[[e$source]]),
        vapply(edges, `[[`, "", "source"))
      prior[[id]] <- legacy_node_signature(node, retained_cap, deps)
      item <- witness$cache[[id]]
      if (is.null(item) || !identical(item$status, "succeeded") ||
          !identical(item$signature, prior[[id]]) ||
          !is.null(attr(item, "workflow_identity_migration", exact = TRUE)))
        return(refuse("LEGACY_EXECUTION_UNVERIFIABLE"))
      record <- list(schema_version = "workflow_identity_migration_v1",
        legacy_signature = item$signature, canonical_signature = step$signature,
        legacy_cache_fingerprint = digest::digest(item, algo = "sha256"),
        authority = authority, provenance = witness$provenance,
        witness_fingerprint = digest::digest(witness, algo = "sha256"),
        analytical_execution_count = 0L)
      record$fingerprint <- workflow_identity_hash(record)
      # Keep ALL legacy fields, including signature, unchanged. The versioned
      # owner metadata carries the successor; the planner validates it explicitly.
      # R-native persistence preserves this attribute. Formats that lose it fail
      # closed instead of assuming legacy signatures are current.
      attr(successor[[id]], "workflow_identity_migration") <- record
      audit[[id]] <- record
    }
    list(ok = TRUE, code = "LEGACY_CACHE_MIGRATED", cache = successor,
      audit = audit, legacy = witness, analytical_execution_count = 0L)
  }, error = function(e) refuse("LEGACY_PROVENANCE_UNVERIFIABLE"))
}
