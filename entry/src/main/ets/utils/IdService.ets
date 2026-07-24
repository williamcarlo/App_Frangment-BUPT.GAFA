export class IdService {
  private static sequence: number = 0

  static create(prefix: string, nowTimestamp: number = Date.now()): string {
    IdService.sequence = (IdService.sequence + 1) % 1679616
    let randomPart: number = Math.floor(Math.random() * 1679616)
    return prefix + '_' + nowTimestamp.toString(36) + '_' +
      IdService.sequence.toString(36) + '_' + randomPart.toString(36)
  }

  static resetSequenceForTesting(): void {
    IdService.sequence = 0
  }
}
