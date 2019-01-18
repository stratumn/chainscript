# Voting

Let's use ChainScript to model something very useful: a voting protocol.
This process is going to be slightly more complex than the asset tracking.

Let's imagine that we have a list of participants and each participant has a
voting power. We want to allow participants to collectively update that list
without a central authority via decentralized voting.

We will use three types of links:

- `accept` links will contain the participants list.
- `propose` links will contain a proposal to update the participants list.
- `vote` links will contain a participant's vote for a proposal.

The rules will be as follow:

- `accept` links can only have one child and it needs to be another `accept`
  link. `accept` links need to reference a `propose` link that has collected
  a majority of votes.
  This prevents forking, lets us easily access the latest participants list (by
  simply fetching the last `accept` link) and see the audit trail of
  participants list changes.
- `propose` links must reference the latest `accept` link.
- `vote` links must reference a `propose` link and contain a participant's
  signature.

## Creating the process

Let's start the process with an initial participants list. The link would look
like:

```json
{
  "data": [
    {
      "name": "alice",
      "power": 2
    },
    {
      "name": "bob",
      "power": 2
    },
    {
      "name": "carol",
      "power": 1
    }
  ],
  "meta": {
    "action": "init",
    "clientId": "github.com/stratumn/go-chainscript",
    "mapId": "voting-123",
    "outDegree": 1,
    "process": { "name": "voting" },
    "step": "accept"
  },
  "version": "1.0.0"
}
```

## Proposing an update

Let's imagine that Bob wants to add Dave to the participants list. Here is what
the corresponding link would look like:

```json
{
  "data": [
    {
      "name": "alice",
      "power": 2
    },
    {
      "name": "bob",
      "power": 2
    },
    {
      "name": "carol",
      "power": 1
    },
    {
      "name": "dave",
      "power": 1
    }
  ],
  "meta": {
    "action": "propose",
    "clientId": "github.com/stratumn/go-chainscript",
    "mapId": "voting-123",
    "outDegree": -1,
    "process": { "name": "voting" },
    "refs": [
      {
        "linkHash": "linkHash of the initial `accept` link",
        "process": "voting"
      }
    ],
    "step": "propose"
  },
  "version": "1.0.0"
}
```

There are a couple of things to note.

We set the `outDegree` to -1, which means that the link is allowed to have an
unlimited number of children. This is required because we want votes to be
children of this link, and we don't want to limit the number of votes.

We have a reference to the latest `accept` link. Voters can easily compare the
current participants list and the one proposed before they vote.

## Voting for a proposal

Participants can now choose to vote for a proposal to accept it.
A vote simply references a `propose` link and signs it.

The vote can be accepted once a majority of participants have voted for the
proposal. In our case, let's imagine that Alice and Bob vote for the proposal.

Alice's vote will look like:

```json
{
  "meta": {
    "action": "vote",
    "clientId": "github.com/stratumn/go-chainscript",
    "mapId": "voting-123",
    "outDegree": 0,
    "prevLinkHash": "linkHash of the `propose` link",
    "process": { "name": "voting" },
    "step": "vote"
  },
  "signatures": [
    {
      "payloadPath": "[version,meta]",
      "publicKey": "Alice's public key",
      "signature": "...",
      "version": "1.0.0"
    }
  ],
  "version": "1.0.0"
}
```

Bob's vote will look like:

```json
{
  "meta": {
    "action": "vote",
    "clientId": "github.com/stratumn/go-chainscript",
    "mapId": "voting-123",
    "outDegree": 0,
    "prevLinkHash": "linkHash of the `propose` link",
    "process": { "name": "voting" },
    "step": "vote"
  },
  "signatures": [
    {
      "payloadPath": "[version,meta]",
      "publicKey": "Bob's public key",
      "signature": "...",
      "version": "1.0.0"
    }
  ],
  "version": "1.0.0"
}
```

The only difference between the two votes is their signature.
We can note that we set `outDegree` to 0 because it doesn't make sense for a
vote to have a child.

## Accepting a proposal

Now that a majority of participants have voted for the proposal, Bob can create
an `accept` link that makes the change effective.

Here is what it would look like:

```json
{
  "data": [
    {
      "name": "alice",
      "power": 2
    },
    {
      "name": "bob",
      "power": 2
    },
    {
      "name": "carol",
      "power": 1
    },
    {
      "name": "dave",
      "power": 1
    }
  ],
  "meta": {
    "action": "update",
    "clientId": "github.com/stratumn/go-chainscript",
    "mapId": "voting-123",
    "outDegree": 1,
    "prevLinkHash": "linkHash of the previous `accept` link",
    "process": { "name": "voting" },
    "refs": [
      {
        "linkHash": "linkHash of Alice's `vote` link",
        "process": "voting"
      },
      {
        "linkHash": "linkHash of Bob's `vote` link",
        "process": "voting"
      }
    ],
    "step": "accept"
  },
  "version": "1.0.0"
}
```

Anyone can now walk the reference graph to find:

- the two `vote` links and verify their signature.
- the `propose` link and verify that the proposed participants list matches the
  list in the current `accept` link.
- the previous `accept` link and verify that the voting power of Alice and Bob
  counts as a majority.

If any of these conditions is false, the link should be rejected.
All these checks can obviously be very easily automated thanks to ChainScript's
clever data format.
