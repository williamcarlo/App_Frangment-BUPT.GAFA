import { describe, expect, it } from '@ohos/hypium'
import {
  FragmentItem,
  FragmentRelation,
  FragmentVisibility,
  ReminderPreference
} from '../main/ets/model/FragmentModel'
import { GraphBuilderService, GraphSnapshot } from '../main/ets/service/GraphBuilderService'

function graphFragment(id: string, displayCode: string): FragmentItem {
  return new FragmentItem({
    id: id,
    displayCode: displayCode,
    tag: id,
    text: id,
    tone: 'self',
    remind: ReminderPreference.NONE,
    visibility: FragmentVisibility.PRIVATE,
    createdAtTimestamp: 1000
  })
}

export default function graphBuilderServiceTest() {
  describe('GraphBuilderService', () => {
    it('rebuilds every active relation and reports orphan relations', 0, () => {
      let fragments: FragmentItem[] = [
        graphFragment('one', '01'),
        graphFragment('two', '02')
      ]
      let relations: FragmentRelation[] = [
        new FragmentRelation('valid', 'one', 'two', 'related', 1000),
        new FragmentRelation('orphan', 'one', 'missing', 'related', 1000)
      ]
      let graph: GraphSnapshot = GraphBuilderService.build(fragments, relations)
      expect(graph.nodes.length).assertEqual(2)
      expect(graph.edges.length).assertEqual(1)
      expect(graph.orphanRelationIds[0]).assertEqual('orphan')
    })

    it('returns an empty graph instead of seed fallback', 0, () => {
      let graph: GraphSnapshot = GraphBuilderService.build([], [])
      expect(graph.nodes.length).assertEqual(0)
      expect(graph.edges.length).assertEqual(0)
    })
  })
}
