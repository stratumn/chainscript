# ChainScript

ChainScript is a data format for business processes traceability.

ChainScript leverages cryptographic hashes to form a directed acyclic graph of
auditable events.

## Links and Segments

At the core of ChainScript there are two main data structures:

- Links
- Segments

Links are immutable and contain the details of an event. Links can reference
other links to form a graph. The links graph forms the audit trail of your
business process.

A link can optionnally be wrapped inside a segment to add mutable data.
The main reason for that is that we want to be able to enrich a link with
external proofs of its existence.
For example we can post a link's hash on the Bitcoin blockchain to prove that
this link existed at some point in time.
We can then use the block header and a merkle path as externally-verifiable
evidence for that claim.
This information cannot be added to the link itself because it is immutable,
hence the need to wrap links in a mutable container.

## Link

A link contains all the data representing a single step in your business process.

Here is what a link looks like in json:

```json
{
  "data": "eyJ1c2VyX2lkIjo0MiwidXNlcl9uYW1lIjoic3BvbmdlYm9iIn0=",
  "meta": {
    "action": "init",
    "clientId": "github.com/stratumn/go-chainscript",
    "data": "eyJhZ2UiOjQyLCJsb2NhdGlvbiI6ImZyYW5jZSJ9",
    "mapId": "my_map",
    "outDegree": -1,
    "prevLinkHash": "mSe7SbLFboaOYhDxLEnXham6xuESNQAjcmR8+95KQyA=",
    "priority": 42,
    "process": { "name": "proc", "state": "initialized" },
    "refs": [{ "linkHash": "Kioq", "process": "some other process" }],
    "step": "init",
    "tags": ["t1", "t2"]
  },
  "signatures": [
    {
      "payloadPath": "[version,data,meta]",
      "publicKey": "LS0tLS1CRUdJTiBFRDI1NTE5IFBVQkxJQyBLRVktLS0tLQpNQ293QlFZREsyVndBeUVBRC9jeEJpWW0vaUo0Ty9sY1dNV3BKZ0IzeGU1eFFPQVRjL0RXTGk3SXBzQT0KLS0tLS1FTkQgRUQyNTUxOSBQVUJMSUMgS0VZLS0tLS0K",
      "signature": "LS0tLS1CRUdJTiBNRVNTQUdFLS0tLS0KU0w2aGc1VXdQSnFMVFdyY3lQMDh0a0pabDZtM29YRkxTN3czM3oxdWlmNXdpbjZOdEIzbzQ4TjBHeVZsM0ZPaQpaeHpKMmxCWGkyd21TdmkxblIvV0RnPT0KLS0tLS1FTkQgTUVTU0FHRS0tLS0tCg==",
      "version": "1.0.0"
    }
  ],
  "version": "1.0.0"
}
```

Here is a detailed description of each field:

- `version` is the version of the link. You can for example use the git tag of the code used to create the link.
- `data` contains the details of your process step. Your application chooses what to put here and how to encode it. For backwards-compatibility you should change the `version` when the structure or encoding of this field changes.
- `meta` contains metadata describing your process step. This metadata adds more structure to your process and helps run automated validation. Note that most of these fields are optional.

  - `meta.action` is the action that created the link.
  - `meta.clientId` is the identifier of the library that created the link (for example, the github url of your repository). It helps receivers find the right code to decode the link.
  - `meta.data` is a placeholder for arbitrary metadata. Your application chooses what to put here and how to encode it. For backwards-compatibility you should change the `version` when the structure or encoding of this field changes.
  - `meta.mapId` is the ID of the process instance.
  - `meta.outDegree` is the number of children this link is allowed to have. A reference doesn't count as a child, only usage of prevLinkHash counts as a link child. It is the application's responsibility to comply with this property.
    - If set to -1, the link can have as many children as it wants.
    - If set to 0, the link can't have any children.
    - If set to n > 0, the link can have at most n children.
  - `meta.prevLinkHash` is the hash of the parent link.
  - `meta.priority` is a priority score that can be associated with the link. It can be used to enable ordering and filtering.
  - `meta.process` is your business process.
    - `meta.process.name` is the name of the process.
    - `meta.process.state` is the current state of the process.
  - `meta.refs` is a list of references to related links. These references can help a viewer understand the _why_ of the link's data.
    - `meta.ref.linkHash` is the hash of the referenced link.
    - `meta.ref.process` is the referenced link's process name.
  - `meta.step` is the name of the process step represented by the link.
  - `meta.tags` is a list of tags that can be used to group and filter links.

- `signatures` contains a list of digital signatures of parts of the link.
  - `signature.version` is the version of the signature scheme used.
  - `signature.payloadPath` is a jmespath query describing what parts of the link are signed.
  - `signature.publicKey` is the public key of the signer.
  - `signature.signature` is the signature bytes.

## Segment

A segment wraps a link to provide some kind of external evidence.
Evidences encompass a broad range of features:

- An evidence can prove that a link was created at a certain point in time (by
  posting the link hash to a public blockchain for example)
- An evidence can prove that a link
  was accepted by a known entity (by showing a digital signature of that entity)
- ...

Here is what a segment looks like in json:

```json
{
  "link": {},
  "meta": {
    "linkHash": "mSe7SbLFboaOYhDxLEnXham6xuESNQAjcmR8+95KQyA=",
    "evidences": [
      {
        "backend": "bitcoin",
        "proof": "Kg==",
        "provider": "testnet:3",
        "version": "1.0.0"
      }
    ]
  }
}
```

Here is a detailed description of each field:

- `linkHash` is the hash of the wrapped link.
- `evidences` is an array of evidence objects.
- `evidence.version` is the version of the evidence format. Your application controls that field and is responsible for updating it when the evidence format changes.
- `evidence.backend` identifies the type of evidence (for example, "bitcoin").
- `evidence.provider` identifies the instance of the backend used. For example, Bitcoin has several networks (testnets and mainnet).
- `evidence.proof` contains the actual evidence proof. Your application chooses what to put here and how to encode it. For backwards-compatibility you should change the `version` when the structure or encoding of this field changes.

## Examples

To see how ChainScript helps solve concrete problems, have a look at the following examples:

- [Asset Tracker](asset-tracker.md)
- [Voting Application](voting.md)
