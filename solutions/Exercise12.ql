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
  AddChatHandler() {
    this.getName() = "add" and
    this.getNumParameter() = 2 and
    this.getParameter(0).getName() = "req" and
    this.getParameter(1).getName() = "res"
  }

  override DataFlow::ParameterNode getRequestParameter() { result = this.getParameter(0) }
}

API::Node lodash() { result = API::moduleImport("lodash") }

class LodashMergeCall extends API::CallNode {
  LodashMergeCall() { this = lodash().getMember("merge").getACall() }
}

class LodashMergeSink extends PrototypePollutionSink {
  LodashMergeSink() {
    exists(LodashMergeCall c | this = c.getArgument([1 .. c.getNumArgument() - 1]))
  }
}

from PrototypePollutionConfiguration config, DataFlow::PathNode source, DataFlow::PathNode sink
where config.hasFlowPath(source, sink)
select sink, source, sink, "Prototype pollution"
