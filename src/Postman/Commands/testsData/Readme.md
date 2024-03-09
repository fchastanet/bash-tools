# structure

```json
{
  "name": "PostmanCliExample",
  "rootCollection": {
    "file": "postman_root_collection.json"
  },
  "collections": {
    "API1": {
      "file": "API1/postman_collection.json",
      "environment": null
    },
    "API2": {
      "file": "API2/postman_collection.json",
      "environment": null
    }
  }
}
```

in postman collections we will have the following structure

Collection PostmanCliExample -> postman_root_collection.json └── API1 ->
API1/postman_collection.json └── Get Data └── API2 ->
API2/postman_collection.json └── Post Data

postman_root_collection.json is

- exported PostmanCliExample collection from postman
- item key will be emptied

API1/postman_collection.json is

- exported PostmanCliExample collection from postman
- item key will contain only item content of the folder API1
- collection \_postmanId and uid will be set using the property id and uid of
  the API1 folder
  - TODO or maybe we should generate a new one ?

same logic for API2/postman_collection.json
