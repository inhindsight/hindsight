# Acquire

`service_acquire` provides a REST API for querying data from storage.
There are two methods for acquiring data: `GET` and `POST`.

## GET

`GET /api/v2/:dataset_id/:subset_id` allows users to query a single dataset.
Users can also `GET /api/v2/:dataset_id`, which is the equivalent to
`GET /api/v2/:dataset_id/default`.

### Parameters

- `fields` - Comma-delimited list of fields to return. Defaults to all (`*`).
- `limit` - Integer to limit the number of results. Defaults to no limit.
- `filter` - Filter to apply to results, using [operators](https://prestosql.io/docs/current/functions/comparison.html). Defaults to no filter.
- `boundary` - Geospatial bounding box in the format of a comma-delimited list of floats (`xmin,ymin,xmax,ymax`). Filters results to geospatial rows that [intersect](https://prestosql.io/docs/current/functions/geospatial.html#ST_Intersects) with the bounding box.
- `before` - An ISO8601 DateTime string. Filters results to temporal rows that fall before the given value.
- `after` - An ISO8601 DateTime string. Filters results to temporal rows that fall after the given value.

## POST

`POST /api/v2/data` allows users to submit a SQL query body. The query will
have full access to PrestoDB [functions](https://prestosql.io/docs/current/functions.html).
