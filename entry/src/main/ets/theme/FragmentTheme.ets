export enum AppPage {
  BOX = 0,
  COLLECTION = 1,
  COMMUNITY = 2
}

export class BoxStyle {
  static readonly PAGE_BG: string = '#F7F3EA'
  static readonly SURFACE: string = '#FFFFFF'
  static readonly CARD_BG: string = 'rgba(255, 255, 255, 0.82)'
  static readonly SOFT_PANEL: string = 'rgba(240, 241, 235, 0.90)'
  static readonly INPUT_BG: string = '#F3F3F0'
  static readonly BUTTON_BG: string = '#222520'
  static readonly TEXT: string = '#222520'
  static readonly TEXT_SOFT: string = '#6F746E'
  static readonly TEXT_MUTED: string = '#A1A49E'
  static readonly TEXT_FAINT: string = '#DADBD6'
  static readonly HAIRLINE: string = 'rgba(55, 57, 55, 0.08)'
  static readonly HAIRLINE_SOFT: string = 'rgba(55, 57, 55, 0.05)'
  static readonly SHADOW: string = 'rgba(44, 47, 45, 0.12)'
  static readonly SHADOW_SOFT: string = 'rgba(44, 47, 45, 0.08)'
  static readonly SELECTED_SOFT: string = '#E4E6E0'
  static readonly SELECTED_TEXT: string = '#465044'
  static readonly GRAPH_ACTIVE: string = 'rgba(64, 73, 67, 0.88)'
  static readonly GRAPH_IDLE: string = 'rgba(139, 143, 137, 0.22)'
  static readonly RADIUS_CARD: number = 28
  static readonly RADIUS_PANEL: number = 30
  static readonly RADIUS_PILL: number = 22
  static readonly ACTION_HEIGHT: number = 58
  static readonly PILL_HEIGHT: number = 44
  static readonly MOTION_FAST: number = 180
  static readonly MOTION_BASE: number = 220
  static readonly GRAPH_NODE_RADIUS: number = 10
  static readonly GRAPH_HIT_RADIUS: number = 24
  static readonly GRAPH_SOURCE_MIN_X: number = 60
  static readonly GRAPH_SOURCE_MAX_X: number = 330
  static readonly GRAPH_SOURCE_MIN_Y: number = 80
  static readonly GRAPH_SOURCE_MAX_Y: number = 450
}
