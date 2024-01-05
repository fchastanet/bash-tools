# PostmanCli

## Commands

### pull

Pull Postman collections to repositories.

### push

Push repositories collections to Postman.

**SUB-ARGUMENTS:**

- list of postman collection's references to push or no argument to push all the
  collections

## Configuration

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

## Algorithms

### push-with-merge

get each collection
