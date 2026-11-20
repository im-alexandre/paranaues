function ansible {
  param (
    [Parameter(Mandatory=$true)]
    [string] $command
  )
  docker run -ti --rm -v ~/.ssh:/root/.ssh -v ~/.aws:/root/.aws -v $(pwd):/apps -w /apps alpine/ansible ansible $command
}
