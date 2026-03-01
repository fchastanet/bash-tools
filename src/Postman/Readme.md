# PostmanCli

## 1. Commands

### 1.1. pull

Pull Postman collections to repositories.

### 1.2. push

Push repositories collections to Postman.

**SUB-ARGUMENTS:**

- list of postman collection's references to push or no argument to push all the collections

## 2. Configuration

```json
{
  "name": "Open Apis",
  "collections": {
    "githubBasic": {
      "collection": "GithubAPI/GitHubAPI-01-Basic_no_auth_postman_collection.json",
      "environment": null
    },
    "githubAdvanced": {
      "collection": "GithubAPI/GitHubAPI-02-Advanced_with_auth_postman_collection.json",
      "environment": null
    },
    "microsoftGraph": {
      "collection": "MicrosoftGraph/MicrosoftGraph-postman_collection.json",
      "environment": null
    }
  }
}
```

## 3. Algorithms

### 3.1. push-with-merge

get each collection
