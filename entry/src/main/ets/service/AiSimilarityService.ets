import { FragmentEmbedding } from '../model/AiModel'

export class SimilarFragmentMatch {
  fragmentId: string = ''
  score: number = 0

  constructor(fragmentId: string, score: number) {
    this.fragmentId = fragmentId
    this.score = score
  }
}

export class AiSimilarityService {
  static bestMatch(
    target: FragmentEmbedding,
    candidates: FragmentEmbedding[],
    minimumScore: number = 0.62
  ): SimilarFragmentMatch | null {
    let best: SimilarFragmentMatch | null = null
    for (let i: number = 0; i < candidates.length; i++) {
      let candidate: FragmentEmbedding = candidates[i]
      if (candidate.fragmentId === target.fragmentId ||
        candidate.model !== target.model ||
        candidate.dimension !== target.dimension) {
        continue
      }
      let score: number = AiSimilarityService.cosine(target.vector, candidate.vector)
      if (score < minimumScore || (best !== null && score <= best.score)) {
        continue
      }
      best = new SimilarFragmentMatch(candidate.fragmentId, score)
    }
    return best
  }

  static cosine(left: number[], right: number[]): number {
    if (left.length === 0 || left.length !== right.length) {
      return 0
    }
    let dot: number = 0
    let leftNorm: number = 0
    let rightNorm: number = 0
    for (let i: number = 0; i < left.length; i++) {
      let leftValue: number = left[i]
      let rightValue: number = right[i]
      if (!Number.isFinite(leftValue) || !Number.isFinite(rightValue)) {
        return 0
      }
      dot += leftValue * rightValue
      leftNorm += leftValue * leftValue
      rightNorm += rightValue * rightValue
    }
    if (leftNorm === 0 || rightNorm === 0) {
      return 0
    }
    return dot / (Math.sqrt(leftNorm) * Math.sqrt(rightNorm))
  }
}
