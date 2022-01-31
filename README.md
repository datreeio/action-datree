# Overview
The Datree CLI provides a policy enforcement solution to run automatic checks for rule violations in Kuberenetes configuration files.  
This action runs the Datree CLI against given k8s configuration file/s in your repository.<br/>
To learn more about Datree, visit the [datree website](https://www.datree.io/).
<br/><br/>
# Setup
To get started, you will need to obtain your Datree account token. Follow the simple instructions described [here](https://hub.datree.io/account-token).
<br/><br/>
Then, configure your token using one of the following ways:
* Set DATREE_TOKEN as a [secret](https://docs.github.com/en/actions/reference/encrypted-secrets) or [environment](https://docs.github.com/en/actions/reference/environment-variables) variable.  
OR
* Pass the token directly into the action, as described in the "Usage" section of this readme.
<br/><br/>
# Usage
In your workflow, set this action as a step:
```
- name: Run Datree's CLI
        uses: datreeio/action-datree@main
        with:
          file: 'someDirectory/someFile.yaml'
          options: '--output simple --schema-version 1.20.0'
          token: 'myAccountToken'
```
<u>**file**</u> - a path to the file/s you wish to run your Datree test against. This can be a single file or a [Glob pattern](https://www.digitalocean.com/community/tools/glob) signifying a directory.
**options** - the desired [Datree CLI arguments](https://hub.datree.io/cli-arguments) for the test. In the above example, two of these arguments(--output and --schema-version) are passed.  
**token** - your Datree account token. See the "Examples" section of this readme for an example that uses a token set as a "secret" variable.
<br/><br/>
# Examples
Here is an example workflow that uses this action to run a Datree policy check on a all of the .yaml files under the current directory, on every push/pull request:
```yaml
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
    
env:
  DATREE_TOKEN: ${{ secrets.DATREE_TOKEN }} 

jobs:
  k8s-policy-check:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v2
        
      - name: Run Datree's CLI
        uses: hadorco/Datree-cli-action@main
        with:
          file: '**/*.yaml'
          options: ''
          token: ''
```
<br/>

<!--# Output
The output of this action will look something like this:

![Alt text](/Resources/output.jpg?raw=true "Optional Title")
--!>
