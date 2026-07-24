import { describe, expect, it } from '@ohos/hypium'
import { FragmentEmbedding } from '../main/ets/model/AiModel'
import {
  AiSimilarityService,
  SimilarFragmentMatch
} from '../main/ets/service/AiSimilarityService'

export default function aiSimilarityServiceTest() {
  describe('AiSimilarityService', () => {
    it('calculates cosine similarity without leaving the device', 0, () => {
      let same: number = AiSimilarityService.cosine([1, 0, 1], [1, 0, 1])
      let orthogonal: number = AiSimilarityService.cosine([1, 0], [0, 1])
      expect(Math.abs(same - 1) < 0.000001).assertEqual(true)
      expect(orthogonal).assertEqual(0)
    })

    it('only compares embeddings from the same vector space', 0, () => {
      let target: FragmentEmbedding =
        new FragmentEmbedding('target', 'text-embedding-v4', 3, [1, 0, 1], 1000)
      let valid: FragmentEmbedding =
        new FragmentEmbedding('valid', 'text-embedding-v4', 3, [0.9, 0, 1], 900)
      let wrongModel: FragmentEmbedding =
        new FragmentEmbedding('wrong', 'other-model', 3, [1, 0, 1], 800)
      let match: SimilarFragmentMatch | null =
        AiSimilarityService.bestMatch(target, [target, wrongModel, valid])
      expect(match === null).assertEqual(false)
      expect(match?.fragmentId).assertEqual('valid')
    })
  })
}
