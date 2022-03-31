# Overview
The Datree CLI provides a policy enforcement solution to run automatic checks for rule violations in Kuberenetes configuration files.  
This action runs the Datree CLI against given k8s configuration file/s in your repository, featuring full Helm support.<br/>
To learn more about Datree, visit the [datree website](https://www.datree.io/).
<br/><br/>
# Setup
Get started in 2 simple steps:
* Obtain your Datree account token by following the instructions described [here](https://hub.datree.io/account-token).
* Configure your token by setting DATREE_TOKEN as a [secret](https://docs.github.com/en/actions/reference/encrypted-secrets) or [environment](https://docs.github.com/en/actions/reference/environment-variables) variable (see "Examples" section of this readme).  <br/><br/>


# Usage
In your workflow, set this action as a step. For example:
```yaml
- name: Run Datree Policy Check
uses: datreeio/action-datree@main
with:
  path: 'someDirectory/someFile.yaml'
  cliArguments: '--schema-version 1.20.0'
```
| Input | Required | Description |
| --- | ----------- | --- |
| **path** | Yes | A path to the file/s you wish to run your Datree test against. This can be a single file or a [Glob pattern](https://www.digitalocean.com/community/tools/glob) signifying a directory. |
| **cliArguments** | No | The desired [Datree CLI arguments](https://hub.datree.io/cli-arguments) for the policy check. In the above example, schema version 1.20.0 will be used.  |
| **isHelmChart** | No | Specify whether the given path is a Helm chart. If this option is unused, the path will be considered as a regular yaml file. |
| **helmArguments** | No | The Helm arguments to be used, if the path is a Helm chart. |
 
*For more information and examples of using this action with Helm, see the "Using Helm" section of this readme*
<br/><br/>
# Examples
Here is an example workflow that uses this action to run a Datree policy check on all of the k8s manifest files under the current directory, on every push/pull request:
```yaml
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
    
env:
  DATREE_TOKEN: ${{ secrets.DATREE_TOKEN }} 

jobs:
  k8sPolicyCheck:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v2
        
      - name: Run Datree Policy Check
        uses: datreeio/action-datree@main
        with:
          path: '**/*.yaml'
          cliArguments: '--only-k8s-files'
```  
Here is another example that runs a policy check on a single file in the root of the repository on every push, using a policy named "Staging". The output will be in simple text, with no colors or emojis:
```yaml
on:
  push:
    branches: [ main ]
    
env:
  DATREE_TOKEN: ${{ secrets.DATREE_TOKEN }} 

jobs:
  k8sPolicyCheck:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v2
        
      - name: Run Datree Policy Check
        uses: datreeio/action-datree@main
        with:
          path: 'file.yaml'
          cliArguments: '--policy Staging --output simple'
```  
<br/>

# Using Helm
This action enables performing policy checks on Helm charts, by utilizing the [Datree Helm plugin](https://github.com/datreeio/helm-datree).  
To test a Helm chart, simply set the "isHelmChart" parameter to "true", and add any Helm arguments you wish to use to the "helmArguments" parameter, like so:
```yaml
- name: Run Datree Policy Check
        uses: datreeio/action-datree@main
        with:
          path: 'myChartDirectory'
          cliArguments: ''
          isHelmChart: 'true'
          helmArguments: '--values values.yaml'
```
<br/>

# Output
The result of your policy checks will look like this:  

![](/Resources/output.gif)
