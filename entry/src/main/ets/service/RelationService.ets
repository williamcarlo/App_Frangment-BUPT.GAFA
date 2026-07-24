import { FragmentRelation } from '../model/FragmentModel'
import { IdService } from '../utils/IdService'

export class RelationService {
  static create(
    fromFragmentId: string,
    toFragmentId: string,
    relationType: string,
    nowTimestamp: number = Date.now()
  ): FragmentRelation {
    return new FragmentRelation(
      IdService.create('relation', nowTimestamp),
      fromFragmentId,
      toFragmentId,
      relationType,
      nowTimestamp
    )
  }

  static sourceFor(fragmentId: string, relations: FragmentRelation[]): string {
    for (let i: number = 0; i < relations.length; i++) {
      if (relations[i].toFragmentId === fragmentId) {
        return relations[i].fromFragmentId
      }
    }
    return ''
  }

  static relatedFragmentIds(fragmentId: string, relations: FragmentRelation[]): string[] {
    let ids: string[] = []
    for (let i: number = 0; i < relations.length; i++) {
      let relation: FragmentRelation = relations[i]
      let relatedId: string = ''
      if (relation.fromFragmentId === fragmentId) {
        relatedId = relation.toFragmentId
      } else if (relation.toFragmentId === fragmentId) {
        relatedId = relation.fromFragmentId
      }
      if (relatedId.length > 0 && ids.indexOf(relatedId) < 0) {
        ids.push(relatedId)
      }
    }
    return ids
  }
}
