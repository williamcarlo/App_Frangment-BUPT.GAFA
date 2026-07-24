import aiSimilarityServiceTest from './AiSimilarityService.test'
import communityServiceTest from './CommunityService.test'
import dateUtilsTest from './DateUtils.test'
import echoServiceTest from './EchoService.test'
import idServiceTest from './IdService.test'
import graphBuilderServiceTest from './GraphBuilderService.test'
import repositoryContractTest from './RepositoryContract.test'
import stableCommunityNodeIdServiceTest from './StableCommunityNodeIdService.test'

export default function testsuite() {
  aiSimilarityServiceTest()
  dateUtilsTest()
  idServiceTest()
  graphBuilderServiceTest()
  echoServiceTest()
  communityServiceTest()
  repositoryContractTest()
  stableCommunityNodeIdServiceTest()
}
