import { FragmentItem, FragmentRelation } from '../model/FragmentModel'
import { GraphEdge, GraphNode } from '../model/GraphModel'
import { StableCommunityNodeIdService } from './StableCommunityNodeIdService'

export class GraphSnapshot {
  nodes: GraphNode[] = []
  edges: GraphEdge[] = []
  orphanRelationIds: string[] = []
}

export class GraphBuilderService {
  static build(fragments: FragmentItem[], relations: FragmentRelation[]): GraphSnapshot {
    let snapshot: GraphSnapshot = new GraphSnapshot()
    let activeFragments: FragmentItem[] = fragments
      .filter((item: FragmentItem) => !item.archived)
      .slice()
      .sort((first: FragmentItem, second: FragmentItem) => first.id.localeCompare(second.id))
    let nodeKeys: Map<string, string> = new Map<string, string>()

    for (let i: number = 0; i < activeFragments.length; i++) {
      let fragment: FragmentItem = activeFragments[i]
      let key: string = 'fragment_' + StableCommunityNodeIdService.hash(fragment.id)
      let position: number[] = GraphBuilderService.position(fragment.id)
      nodeKeys.set(fragment.id, key)
      snapshot.nodes.push(new GraphNode(
        key,
        fragment.displayCode,
        fragment.tag,
        fragment.tone,
        position[0],
        position[1],
        fragment.id
      ))
    }

    for (let i: number = 0; i < relations.length; i++) {
      let relation: FragmentRelation = relations[i]
      let fromKey: string | undefined = nodeKeys.get(relation.fromFragmentId)
      let toKey: string | undefined = nodeKeys.get(relation.toFragmentId)
      if (fromKey === undefined || toKey === undefined) {
        snapshot.orphanRelationIds.push(relation.id)
        continue
      }
      snapshot.edges.push(new GraphEdge(
        'relation_' + StableCommunityNodeIdService.hash(relation.id),
        fromKey,
        toKey,
        GraphBuilderService.colorFor(relation.relationType)
      ))
    }
    return snapshot
  }

  private static position(fragmentId: string): number[] {
    let first: number = GraphBuilderService.numericHash(fragmentId + ':x')
    let second: number = GraphBuilderService.numericHash(fragmentId + ':y')
    return [
      68 + first % 244,
      88 + second % 348
    ]
  }

  private static numericHash(value: string): number {
    let hashValue: number = 0
    for (let i: number = 0; i < value.length; i++) {
      hashValue = (hashValue * 31 + value.charCodeAt(i)) >>> 0
    }
    return hashValue
  }

  private static colorFor(relationType: string): string {
    if (relationType === 'action') {
      return 'rgba(143, 167, 131, 0.28)'
    }
    if (relationType === 'inspired') {
      return 'rgba(176, 125, 145, 0.24)'
    }
    if (relationType === 'semantic_ai') {
      return 'rgba(121, 144, 179, 0.28)'
    }
    return 'rgba(113, 151, 160, 0.24)'
  }
}
