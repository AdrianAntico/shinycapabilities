args<-commandArgs(TRUE);stopifnot(length(args)==4L)
source(args[[1]])
.libPaths(c(args[[2]],args[[3]],.libPaths()),include.site=FALSE)
n<-asNamespace('AnalyticsShinyApp');sn<-asNamespace('shinycapabilities')
stopifnot(identical(utils::packageDescription('AnalyticsShinyApp')$RemoteSha,'58916edc5a2665d036911e11fcae6bd7a356b385'))
for(z in list(c('FinancialIntelligence','fi_valuation'),c('FinancialIntelligence','fi_risk'),c('ScientificIntelligence','sci_queue_mmc'),c('shinycapabilities','execute_workflow_plan'),c('AnalyticsShinyApp','genai_ollama_chat'))) trace(z[2],where=asNamespace(z[1]),tracer=quote(stop('UNEXPECTED_EXECUTION_DURING_MIGRATION')),print=FALSE)
p<-args[[4]]
stopifnot(identical(digest::digest(file=file.path(p,'RETAINED_LIVE.rds'),algo='sha256'),'9278a53e305e5a5c2c473a58a238f4f98fecba25dd80b867ce509c97d70d2426'),identical(digest::digest(file=file.path(p,'WORKFLOW_IDENTITY_BOUNDARY.rds'),algo='sha256'),'e600b4586f5efe6eed795c5d738e1d02c39ec7f5a7c6433caec2cfc1f9a46047'))
x<-readRDS(file.path(p,'RETAINED_LIVE.rds'));b<-readRDS(file.path(p,'WORKFLOW_IDENTITY_BOUNDARY.rds'))
r<-n$workflow_studio_registry();wf<-n$workflow_project_active(x$initial$state)
caps<-list(); owners<-list()
for (node in b$variants$original$nodes) {
 cap<-shinycapabilities::capability_registry_get(r,node$capability_id)
 caps[[cap$id]]<-cap[c('id','version','implementation_fingerprint','resource_hints','execution_contract')]
 binding<-cap$resource_hints$specialist_consultation
 output<-b$cache[[node$id]]$outputs[[binding$output]];s<-output$specialist_source
 stopifnot(identical(s$fingerprint,n$collaboration_hash(s[setdiff(names(s),'fingerprint')])),
 identical(s$native_fingerprint,n$collaboration_hash(output[[binding$field]])),
 identical(s$implementation,cap$implementation_fingerprint),identical(s$capability_version,cap$version),
 identical(s$executor_fingerprint,cap$resource_hints$specialist_executor_fingerprint),
 identical(s$config_fingerprint,n$collaboration_hash(node$config)))
 edges<-Filter(function(e)e$target==node$id,b$variants$original$edges)
 inputs<-setNames(lapply(edges,function(e)b$cache[[e$source]]$outputs[[e$source_port]]),vapply(edges,`[[`,'','target_port'))
 stopifnot(identical(s$inputs_fingerprint,n$collaboration_hash(inputs)))
 spec<-n$analytical_artifact_agent_surfaces()[[binding$surface]]
 stopifnot(isTRUE(spec$authority$ok),n$workflow_owner_records_equal(s$owner,spec$authority))
 owners[[node$id]]<-s$owner
}
authority<-list(project_id=x$initial$state$metadata$project_id,workflow_id=wf$workflow_id,input_revision=wf$current_revision_id,
 dataset=x$initial$state$metadata$active_dataset,owners=owners)
provenance<-list(workstation_sha=utils::packageDescription('AnalyticsShinyApp')$RemoteSha,
 retained_live=digest::digest(file=file.path(p,'RETAINED_LIVE.rds'),algo='sha256'),
 retained_boundary=digest::digest(file=file.path(p,'WORKFLOW_IDENTITY_BOUNDARY.rds'),algo='sha256'))
witness<-list(graph=b$variants$original,cache=b$cache,capabilities=caps,authority=authority,provenance=provenance)
bytes<-serialize(witness,NULL)
verify<-function(z)identical(serialize(z,NULL),bytes)
res<-lapply(b$variants,function(g)shinycapabilities::migrate_workflow_cache(r,g,witness,authority,verify))
print(lapply(res,function(z)z[c('ok','code')]))
stopifnot(all(vapply(res,function(z)isTRUE(z$ok),logical(1))))
for (id in names(b$cache)) stopifnot(identical(res$reordered$cache[[id]]$outputs,b$cache[[id]]$outputs))
print(lapply(shinycapabilities::plan_workflow(r,b$variants$reordered,cache=res$reordered$cache)$steps,function(z)z[c('node_id','signature','action')]))
saveRDS(list(witness=witness,result=res$reordered),file.path(p,'OWNER_MIGRATION.rds'))
cat('RETAINED_MIGRATION_PASS; ANALYTICAL_CALLS=0\n')
x<-readRDS(file.path(p,'RETAINED_REVIEWED.rds'));g<-n$workflow_project_active(x$state)$draft$graph
actual<-shinycapabilities::migrate_workflow_cache(r,g,witness,authority,verify)
print(actual[c('ok','code')]); stopifnot(actual$ok)


stopifnot(identical(n$workflow_work_hash(res$reordered$cache),n$workflow_work_hash(b$cache)))
fixture<-lapply(names(b$cache),function(id)list(node=id,legacy=b$cache[[id]]$signature,canonical=res$reordered$audit[[id]]$canonical_signature,outputs_identical=identical(b$cache[[id]]$outputs,res$reordered$cache[[id]]$outputs)))
jsonlite::write_json(list(fixtures=fixture,analytical_calls=0,provider_calls=0,actual_reopened_graph_migrates=actual$ok,provenance=provenance),file.path(p,'OWNER_MIGRATION.json'),pretty=TRUE,auto_unbox=TRUE)

