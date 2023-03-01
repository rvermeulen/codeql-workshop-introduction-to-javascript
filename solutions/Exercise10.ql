import javascript

API::Node lodash() { result = API::moduleImport("lodash") }

class LodashMergeCall extends API::CallNode {
  LodashMergeCall() { this = lodash().getMember("merge").getACall() }
}

select any(LodashMergeCall c).getAnArgument()
