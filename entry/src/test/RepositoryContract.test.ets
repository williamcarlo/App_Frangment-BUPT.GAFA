import { describe, expect, it } from '@ohos/hypium'
import { FragmentItem, FragmentRelation } from '../main/ets/model/FragmentModel'
import { SeedData } from '../main/ets/data/SeedData'

export default function repositoryContractTest() {
  describe('Repository seed contract', () => {
    it('uses unique stable fragment IDs', 0, () => {
      let fragments: FragmentItem[] = SeedData.fragments(1000000)
      let ids: string[] = []
      let unique: boolean = true
      for (let i: number = 0; i < fragments.length; i++) {
        if (ids.indexOf(fragments[i].id) >= 0) {
          unique = false
        }
        ids.push(fragments[i].id)
      }
      expect(unique).assertEqual(true)
    })

    it('only seeds relations whose endpoints exist', 0, () => {
      let fragments: FragmentItem[] = SeedData.fragments(1000000)
      let relations: FragmentRelation[] = SeedData.relations(1000000)
      let valid: boolean = true
      let ids: string[] = fragments.map((item: FragmentItem) => item.id)
      for (let i: number = 0; i < relations.length; i++) {
        if (ids.indexOf(relations[i].fromFragmentId) < 0 ||
          ids.indexOf(relations[i].toFragmentId) < 0) {
          valid = false
        }
      }
      expect(valid).assertEqual(true)
    })
  })
}
