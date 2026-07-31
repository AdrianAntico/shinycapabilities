#' Define a typed capability port
#' @param type Stable semantic type name.
#' @param required Whether the input is mandatory.
#' @param multiple Whether the port accepts multiple connections.
#' @param description Optional human-readable description.
#' @export
port_type <- function(type, required = TRUE, multiple = FALSE, description = NULL) {
  stopifnot(is.character(type), length(type) == 1L, nzchar(type))
  structure(
    list(
      type = type,
      required = isTRUE(required),
      multiple = isTRUE(multiple),
      description = description
    ),
    class = "shinycap_port"
  )
}

normalize_capability_presentation <- function(value = list()) {
  value <- value %||% list()
  explicit <- length(value) > 0L
  allowed <- c(
    "group_id", "group_label", "group_order", "display_order", "icon_id",
    "short_summary", "compact_summary", "input_port_labels",
    "output_port_labels", "emphasis", "accessibility_label"
  )
  unknown <- setdiff(names(value), allowed)
  if (length(unknown)) {
    stop("Unknown presentation metadata: ", paste(unknown, collapse = ", "), call. = FALSE)
  }
  defaults <- list(
    group_id = "other", group_label = "Other", group_order = 1000,
    display_order = 1000, icon_id = "generic", short_summary = NULL,
    compact_summary = NULL, input_port_labels = list(),
    output_port_labels = list(), emphasis = "default",
    accessibility_label = NULL
  )
  result <- utils::modifyList(defaults, value, keep.null = TRUE)
  attr(result, "host_supplied") <- explicit
  result
}

#' Define a schema-driven configuration field
#' @param type Control type.
#' @param label Human-readable field label.
#' @param default Default value.
#' @param choices Optional available values.
#' @param required Whether a value is required.
#' @param minimum,maximum,step Optional numeric control bounds.
#' @param help Optional help text.
#' @export
config_field <- function(type, label, default = NULL, choices = NULL, required = FALSE,
                         minimum = NULL, maximum = NULL, step = NULL, help = NULL) {
  supported <- c(
    "select", "multi_select", "text", "numeric", "checkbox", "slider",
    "resource", "property", "expression", "custom"
  )
  if (!type %in% supported) stop("Unsupported configuration field type: ", type, call. = FALSE)
  list(
    type = type, label = label, default = default, choices = choices,
    required = isTRUE(required), minimum = minimum, maximum = maximum,
    step = step, help = help
  )
}

#' Create a capability registry
#' @export
capability_registry <- function() {
  structure(new.env(parent = emptyenv()), class = "shinycap_registry")
}

#' Register a capability definition
#' @param id Stable capability identifier.
#' @param version Semantic capability version.
#' @param display_name Human-readable name.
#' @param description Capability description.
#' @param category Palette category.
#' @param inputs,outputs Named lists of ports.
#' @param config Named configuration schema.
#' @param validate Optional validation function.
#' @param execute Host-owned execution function.
#' @param custom_ui,custom_server Optional Shiny module hooks.
#' @param summarize Optional output summarizer.
#' @param implementation_fingerprint Stable implementation identity.
#' @param cache_policy Cache reuse policy.
#' @param cancellation Whether cancellation is supported.
#' @param execution_profile One of inline, background_r, network, or planning_only.
#' @param expected_duration Expected duration label or seconds.
#' @param progress_support Whether phase-level or granular progress is supported.
#' @param timeout Maximum elapsed seconds before a typed timeout.
#' @param retry_policy Closed retry policy. Automatic retries are disabled by default.
#' @param maximum_concurrency Optional capability-specific concurrency ceiling.
#' @param resource_hints Domain-neutral resource metadata.
#' @param icon,style Legacy presentation metadata.
#' @param presentation Optional host-supplied, domain-neutral presentation metadata.
#' @export
register_capability <- function(
    id, version, display_name, description = "", category = "Other",
    inputs = list(), outputs = list(), config = list(),
    validate = NULL, execute = NULL, custom_ui = NULL, custom_server = NULL,
    summarize = NULL, implementation_fingerprint = NULL,
    cache_policy = c("reuse_current", "never"), cancellation = FALSE,
    execution_profile = c("inline", "background_r", "network", "planning_only"),
    expected_duration = NULL, progress_support = c("phase", "none", "granular"),
    timeout = 300, retry_policy = c("none", "explicit"),
    maximum_concurrency = NULL,
    resource_hints = list(), icon = NULL, style = list(),
    presentation = list()) {
  cache_policy <- match.arg(cache_policy)
  execution_profile <- match.arg(execution_profile)
  progress_support <- match.arg(progress_support)
  retry_policy <- match.arg(retry_policy)
  timeout <- as.numeric(timeout)
  if (length(timeout) != 1L || is.na(timeout) || timeout <= 0) {
    stop("Capability timeout must be one positive number of seconds.", call. = FALSE)
  }
  if (!is.null(maximum_concurrency)) {
    maximum_concurrency <- as.integer(maximum_concurrency)
    if (length(maximum_concurrency) != 1L || is.na(maximum_concurrency) ||
        maximum_concurrency < 1L) {
      stop("Maximum concurrency must be one positive integer.", call. = FALSE)
    }
  }
  if (!grepl("^[a-z][a-z0-9_.-]+$", id)) stop("Capability id is not stable.", call. = FALSE)
  if (!grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", version)) stop("Version must be semantic.", call. = FALSE)
  inputs <- as_named_list(inputs)
  outputs <- as_named_list(outputs)
  if (any(!vapply(c(inputs, outputs), inherits, logical(1), "shinycap_port"))) {
    stop("Every input and output must be created with port_type().", call. = FALSE)
  }
  definition <- list(
    id = id, version = version, display_name = display_name,
    description = description, category = category, inputs = inputs,
    outputs = outputs, config = as_named_list(config),
    validate = validate, execute = execute, custom_ui = custom_ui,
    custom_server = custom_server, summarize = summarize,
    implementation_fingerprint = implementation_fingerprint %||%
      stable_hash(list(id = id, version = version)),
    cache_policy = cache_policy, cancellation = isTRUE(cancellation),
    execution_profile = execution_profile,
    expected_duration = expected_duration,
    progress_support = progress_support,
    timeout = timeout,
    retry_policy = retry_policy,
    maximum_concurrency = maximum_concurrency,
    resource_hints = resource_hints, icon = icon, style = style,
    presentation = normalize_capability_presentation(presentation)
  )
  class(definition) <- "shinycap_capability"
  definition
}

#' Add a capability to a registry
#' @param registry Capability registry.
#' @param capability Capability definition.
#' @export
capability_registry_add <- function(registry, capability) {
  stopifnot(inherits(registry, "shinycap_registry"))
  stopifnot(inherits(capability, "shinycap_capability"))
  assign(capability$id, capability, envir = registry)
  invisible(registry)
}

#' Retrieve a capability
#' @param registry Capability registry.
#' @param id Capability identifier.
#' @export
capability_registry_get <- function(registry, id) {
  if (!exists(id, envir = registry, inherits = FALSE)) return(NULL)
  get(id, envir = registry, inherits = FALSE)
}

#' List capabilities deterministically
#' @param registry Capability registry.
#' @export
capability_registry_list <- function(registry) {
  ids <- sort(ls(registry, all.names = TRUE))
  unname(lapply(ids, capability_registry_get, registry = registry))
}
