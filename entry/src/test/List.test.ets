import aiSimilarityServiceTest from './AiSimilarityService.test'
import communityServiceTest from './CommunityService.test'
import dateUtilsTest from './DateUtils.test'
import echoServiceTest from './EchoService.test'
import idServiceTest from './IdService.test'
import repositoryContractTest from './RepositoryContract.test'

export default function testsuite() {
  aiSimilarityServiceTest()
  dateUtilsTest()
  idServiceTest()
  echoServiceTest()
  communityServiceTest()
  repositoryContractTest()
}
