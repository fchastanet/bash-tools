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

info keep only the following information

```json
{
  "info": {
    "_postman_id": "caa8b54a-eb5e-4134-8ae2-a3946a428ec7",
    "name": "OpenApis",
    "description": "",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  }
}
```

Create item folder for each collection with following properties:

- name: name of the collection
- item: containing item of the original collection
  - remove the properties (id, uid)
- event: containing event of the original collection

Move and merge some properties at root level (allows uniformization):

- variable: containing variable of the each collection

Example:

```json
{
  "info": {
    "_postman_id": "caa8b54a-eb5e-4134-8ae2-a3946a428ec7",
    "name": "OpenApis",
    "description": "",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "MongoDBDataAPI",
      "item": [],
      "event": []
    },
    {
      "name": "GitHubAPI-01-Basic_no_auth",
      "item": [],
      "event": []
    }
  ],
  "variable": []
}
```
