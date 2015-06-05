# pco_api

[![Circle CI](https://circleci.com/gh/planningcenter/pco_api_ruby/tree/master.svg?style=svg)](https://circleci.com/gh/planningcenter/pco_api_ruby/tree/master)

`pco_api` is a Rubygem that provides a simple wrapper around our RESTful JSON API at https://api.planningcenteronline.com.

## Installation

```
gem install pco_api
```

## Usage

1. Create a new API object, passing in your credentials (either HTTP Basic or OAuth2 access token):

    ```ruby
    # authenticate with HTTP Basic:
    api = PCO::API.new(basic_auth_token: 'token', basic_auth_secret: 'secret')
    # ...or authenticate with an OAuth2 access token (use the 'oauth2' gem to obtain the token)
    api = PCO::API.new(oauth_access_token: 'token')
    ```

2. Chain path elements together as method calls.

    ```ruby
    api.people.v2.households
    # /people/v2/households
    ```

3. For IDs, treat the object like a hash (use square brackets).

    ```ruby
    api.people.v2.households[1]
    # /people/v2/households/1
    ```

4. To execute the request, use `get`, `post`, `patch`, or `delete`, optionally passing arguments.

    ```ruby
    api.people.v2.households.get(order: 'name')
    # GET /people/v2/households?order=name
    ```

## Example

```ruby
require 'pco_api'

api = PCO::API.new(basic_auth_token: 'token', basic_auth_secret: 'secret')
api.people.v2.people.get(order: 'last_name')
```

...which returns something like:

```ruby
{
  "links" => {
    "self" => "https://api.planningcenteronline.com/people/v2/people?order=last_name",
    "next" => "https://api.planningcenteronline.com/people/v2/people?offset=25&order=last_name"
  },
  "data"=> [
    {
      "type" => "Person",
      "id" => "271",
      "first_name" => "Jean",
      "middle_name" => nil,
      "last_name" => "Abernathy",
      "birthdate" => "1885-01-01",
      "anniversary" => nil,
      "gender" => "F",
      "grade" => -1,
      "child" => false,
      "status" => "active",
      "school_type" => nil,
      "graduation_year" => nil,
      "site_administrator" => false,
      "people_permissions" => nil,
      "created_at" => "2015-04-01T20:18:22Z",
      "updated_at" => "2015-04-10T18:59:51Z",
      "avatar" => nil,
      "links" => {
        "self" => "https://api.planningcenteronline.com/people/v2/people/271"
      }
    },
    # ...
  ],
  "meta" => {
    "total_count" => 409,
    "count" => 25,
    "next" => {
      "offset" => 25
    },
    "orderable_by" => [
      "first_name",
      "middle_name",
      "last_name",
      "birthdate",
      "anniversary",
      "gender",
      "grade",
      "child",
      "status",
      "school_type",
      "graduation_year",
      "site_administrator",
      "people_permissions",
      "created_at",
      "updated_at"
    ],
    "filterable_by" => [
      "first_name",
      "middle_name",
      "last_name",
      "birthdate",
      "anniversary",
      "gender",
      "grade",
      "child",
      "status",
      "school_type",
      "graduation_year",
      "site_administrator",
      "people_permissions",
      "created_at",
      "updated_at"
    ],
    "can_include" => [
      "emails",
      "addresses",
      "phone_numbers",
      "households",
      "school",
      "inactive_reason",
      "marital_status",
      "name_prefix",
      "name_suffix",
      "field_data",
      "apps"
    ]
  }
}
```

## get()

`get()` works for a collection (index) and a single resource (show).

```ruby
# collection
api.people.v2.people.get(order: 'last_name')
# => { data: array_of_resources }

# single resource
api.people.v2.people[1].get
# => { data: resource_hash }
```

## post()

`post()` sends a POST request to create a new resource. You *must* wrap your resource with
a `{ data: { ... } }` hash.

```ruby
api.people.v2.people.post(data: { type: 'Person', attributes: { first_name: 'Tim', last_name: 'Morgan' } })
# => { data: resource_hash }
```

## patch()

`patch()` sends a PATCH request to update an existing resource. You *must* wrap your resource with
a `{ data: { ... } }` hash.

```ruby
api.people.v2.people[1].patch(data: { type: 'Person', id: 1, attributes: { first_name: 'Tim', last_name: 'Morgan' } })
# => { data: resource_hash }
```

## delete()

`delete()` sends a DELETE request to delete an existing resource. This method returns `true` if the delete was successful.

```ruby
api.people.v2.people[1].delete
# => true
```

## Errors

The following errors may be raised, which you should rescue in most circumstances.

| HTTP Status Codes   | Error Class                                                               |
| ------------------- | ------------------------------------------------------------------------- |
| 400                 | `PCO::API::Errors::BadRequest` < `PCO::API::Errors::ClientError`          |
| 401                 | `PCO::API::Errors::Unauthorized` < `PCO::API::Errors::ClientError`        |
| 403                 | `PCO::API::Errors::Forbidden` < `PCO::API::Errors::ClientError`           |
| 404                 | `PCO::API::Errors::NotFound` < `PCO::API::Errors::ClientError`            |
| 405                 | `PCO::API::Errors::MethodNotAllowed` < `PCO::API::Errors::ClientError`    |
| 422                 | `PCO::API::Errors::UnprocessableEntity` < `PCO::API::Errors::ClientError` |
| other 4xx errors    | `PCO::API::Errors::ClientError`                                           |
| 500                 | `PCO::API::Errors::InternalServerError` < `PCO::API::Errors::ServerError` |
| other 5xx errors    | `PCO::API::Errors::ServerError`                                           |

The exception class has the following methods:

| Method  | Content                                         |
| ------- | ----------------------------------------------- |
| status  | HTTP status code returned by the server         |
| message | the body of the response returned by the server |

The `message` will usually be a hash (produced by parsing the response JSON),
but in the case of some server errors, may be a string containing the raw response.

## Copyright & License

Copyright 2015, Ministry Centered Technologies. Licensed MIT.
