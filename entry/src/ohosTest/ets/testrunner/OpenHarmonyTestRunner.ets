import { abilityDelegatorRegistry, TestRunner } from '@kit.TestKit'
import { UIAbility, Want } from '@kit.AbilityKit'

let delegator: abilityDelegatorRegistry.AbilityDelegator

export default class OpenHarmonyTestRunner implements TestRunner {
  onPrepare(): void {
  }

  onRun(): void {
    delegator = abilityDelegatorRegistry.getAbilityDelegator()
    let argumentsValue: abilityDelegatorRegistry.AbilityDelegatorArgs =
      abilityDelegatorRegistry.getArguments()
    let want: Want = {
      bundleName: argumentsValue.bundleName,
      abilityName: 'TestAbility',
      moduleName: argumentsValue.parameters['-m']
    }
    let monitor: abilityDelegatorRegistry.AbilityMonitor = {
      abilityName: 'TestAbility',
      moduleName: argumentsValue.parameters['-m'],
      onAbilityCreate: (ability: UIAbility): void => {
      }
    }
    delegator.addAbilityMonitor(monitor)
    delegator.startAbility(want)
  }
}
