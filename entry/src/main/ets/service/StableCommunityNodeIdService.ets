export class StableCommunityNodeIdService {
  static create(
    rootFragmentId: string,
    parentNodeId: string,
    branchType: string,
    content: string,
    sourceIdentity: string
  ): string {
    let canonical: string = StableCommunityNodeIdService.normalize(rootFragmentId) + '\n' +
      StableCommunityNodeIdService.normalize(parentNodeId) + '\n' +
      StableCommunityNodeIdService.normalize(branchType) + '\n' +
      StableCommunityNodeIdService.normalize(content) + '\n' +
      StableCommunityNodeIdService.normalize(sourceIdentity)
    return 'community_' + StableCommunityNodeIdService.hash(canonical)
  }

  static hash(value: string): string {
    let hashValue: number = 2166136261
    for (let i: number = 0; i < value.length; i++) {
      hashValue = (hashValue ^ value.charCodeAt(i)) * 16777619
      hashValue = hashValue >>> 0
    }
    return hashValue.toString(36)
  }

  private static normalize(value: string): string {
    return value.trim().toLowerCase()
  }
}
