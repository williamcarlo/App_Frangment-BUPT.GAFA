import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { abilityDelegatorRegistry } from '@kit.TestKit'
import { Hypium } from '@ohos/hypium'
import testsuite from '../test/List.test'

export default class TestAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Hypium.hypiumTest(
      abilityDelegatorRegistry.getAbilityDelegator(),
      abilityDelegatorRegistry.getArguments(),
      testsuite
    )
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('testability/pages/Index')
  }
}
