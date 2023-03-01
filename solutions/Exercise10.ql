import javascript

API::Node lodash() { result = API::moduleImport("lodash") }

class LodashMergeCall extends API::CallNode {
  LodashMergeCall() { this = lodash().getMember("merge").getACall() }
}

from LodashMergeCall c
select c.getArgument([1 .. c.getNumArgument() - 1])
