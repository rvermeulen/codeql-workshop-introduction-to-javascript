/**
 * @kind path-problem
 */

import javascript
import DataFlow::PathGraph

abstract class ApiHandler extends DataFlow::Node {
  abstract DataFlow::ParameterNode getRequestParameter();
}

abstract class PrototypePollutionSink extends DataFlow::Node { }

class PrototypePollutionConfiguration extends TaintTracking::Configuration {
  PrototypePollutionConfiguration() { this = "PrototypePollutionConfiguration" }

  override predicate isSource(DataFlow::Node source) {
    source = any(ApiHandler h).getRequestParameter()
  }

  override predicate isSink(DataFlow::Node sink) { sink instanceof PrototypePollutionSink }
}

class AddChatHandler extends ApiHandler, DataFlow::FunctionNode {
  AddChatHandler() { none() }

  override DataFlow::ParameterNode getRequestParameter() { none() }
}

from PrototypePollutionConfiguration config, DataFlow::PathNode source, DataFlow::PathNode sink
where config.hasFlowPath(source, sink)
select sink, source, sink, "Prototype pollution"
