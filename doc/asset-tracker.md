# Asset Tracking

Let's use ChainScript to model a very common process in supply chain: tracking
assets ownership.

The name of our process will be `asset-tracker`.
All our links will have `link.meta.process.name = asset-tracker`.

We will create one instance of that process per asset.
The ID of each instance (`link.meta.mapId`) will be the ID of the asset that
we're tracking.

Our `link.data` structure will be very simple. It will be a canonical JSON
object containing the name of the current asset owner:

```json
{
  "owner": "alice"
}
```

Our process has only two steps:

- `init` creates the asset and starts the ownership trail.
- `transfer` transfers the asset to someone.

An asset can be transfered to only one person: we need to prevent branching.
We will use the `link.meta.outDegree` to model that, by setting it to 1.
This will ensure that a link can have only one child.

We will leverage digital signatures to ensure that the ownership changes are
correct: a `transfer` steps needs to include a valid signature from the current
owner.

## Creating Assets

Let's create two assets belonging to Alice: `asset-1` and `asset-2`.
Their `init` links will look like:

```json
{
  "data": "ewogICJvd25lciI6ICJhbGljZSIKfQ==",
  "meta": {
    "action": "init",
    "clientId": "github.com/stratumn/js-chainscript",
    "mapId": "asset-1",
    "outDegree": 1,
    "process": { "name": "asset-tracker", "state": "asset-created" },
    "step": "init",
    "tags": ["alice"]
  },
  "signatures": [
    {
      "payloadPath": "[version,data,meta]",
      "publicKey": "...",
      "signature": "...",
      "version": "1.0.0"
    }
  ],
  "version": "1.0.0"
}
```

```json
{
  "data": "ewogICJvd25lciI6ICJhbGljZSIKfQ==",
  "meta": {
    "action": "init",
    "clientId": "github.com/stratumn/js-chainscript",
    "mapId": "asset-2",
    "outDegree": 1,
    "process": { "name": "asset-tracker", "state": "asset-created" },
    "step": "init",
    "tags": ["alice"]
  },
  "signatures": [
    {
      "payloadPath": "[version,data,meta]",
      "publicKey": "...",
      "signature": "...",
      "version": "1.0.0"
    }
  ],
  "version": "1.0.0"
}
```

In those links, `data` is the base64 encoding of the following json:

```json
{
  "owner": "alice"
}
```

## Transfering Assets

Now that our assets are created, Alice can transfer them to someone else.
Malicious actors could try to transfer them too, but since we'll verify that
the transfer link contains a signature from the current owner, cheaters will
be detected and their links will be rejected automatically.

A transfer to Bob of `asset-1` would look like:

```json
{
  "data": "ewogICJvd25lciI6ICJib2IiCn0=",
  "meta": {
    "action": "transfer",
    "clientId": "github.com/stratumn/js-chainscript",
    "mapId": "asset-1",
    "outDegree": 1,
    "process": { "name": "asset-tracker", "state": "asset-transferred" },
    "step": "transfer",
    "tags": ["alice", "bob"]
  },
  "signatures": [
    {
      "payloadPath": "[version,data,meta]",
      "publicKey": "...",
      "signature": "...",
      "version": "1.0.0"
    }
  ],
  "version": "1.0.0"
}
```

This link's `data` is the base64 encoding of the following json:

```json
{
  "owner": "bob"
}
```

Now Bob can keep transferring `asset-1` and everyone can see a clear ownership
trail for the asset by filtering by `link.meta.mapId == 'asset-1'`.

## Sample Application

If you'd like to see some code, have a look at our [Sample Apps](https://github.com/stratumn/sample-apps) repository.
