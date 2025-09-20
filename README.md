# CarbonVote

A decentralized community governance system for emission reduction targets and green energy transitions built on the Stacks blockchain using Clarity smart contracts.

## Overview

CarbonVote enables communities to democratically propose, vote on, and execute carbon emission reduction initiatives and green energy projects. The platform uses STX token holdings as voting power, ensuring stakeholders with economic interest have proportional influence in environmental decision-making.

## Features

- **Proposal Creation**: Community members can create proposals for carbon reduction targets and green energy initiatives
- **Weighted Voting**: Voting power is determined by STX token balance (minimum 1 STX required)
- **Time-bound Voting**: Each proposal has a 1-week voting period (1008 blocks)
- **Proposal Execution**: Successful proposals are automatically tracked and contribute to cumulative carbon reduction targets
- **Vote Tracking**: Transparent recording of all votes with immutable blockchain storage
- **Voting Statistics**: Real-time voting statistics and participation rates
- **Proposal Status Monitoring**: Track proposal states (active, passed, rejected)

## Technical Specifications

- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity v2
- **Epoch**: 2.5
- **Voting Duration**: 1008 blocks (approximately 1 week)
- **Minimum Voting Power**: 1,000,000 microSTX (1 STX)
- **Contract Owner**: Deployer address

### Data Structures

#### Proposals
```clarity
{
  title: (string-ascii 100),
  description: (string-ascii 500),
  target-reduction: uint,
  energy-type: (string-ascii 50),
  proposer: principal,
  start-block: uint,
  end-block: uint,
  yes-votes: uint,
  no-votes: uint,
  total-voters: uint,
  executed: bool
}
```

#### Votes
```clarity
{
  vote: bool,
  voting-power: uint,
  block-height: uint
}
```

## Installation

### Prerequisites
- [Clarinet](https://docs.hiro.so/clarinet) installed
- [Node.js](https://nodejs.org/) v16 or higher
- Stacks wallet for deployment

### Setup
1. Clone the repository:
```bash
git clone <repository-url>
cd CarbonVote
```

2. Navigate to the contract directory:
```bash
cd CarbonVote_contract
```

3. Install dependencies:
```bash
npm install
```

4. Check contract syntax:
```bash
clarinet check
```

5. Run tests:
```bash
clarinet test
```

## Usage Examples

### Creating a Proposal
```clarity
(contract-call? .CarbonVote create-proposal
  "Solar Panel Installation"
  "Install 100kW solar panels to reduce grid dependency"
  u50  ;; 50 tons CO2 reduction target
  "solar")
```

### Voting on a Proposal
```clarity
;; Vote YES on proposal ID 1
(contract-call? .CarbonVote vote u1 true)

;; Vote NO on proposal ID 1
(contract-call? .CarbonVote vote u1 false)
```

### Executing a Proposal
```clarity
;; Execute proposal ID 1 (only after voting period ends and proposal passes)
(contract-call? .CarbonVote execute-proposal u1)
```

### Updating Voting Power
```clarity
;; Update your voting power after STX balance changes
(contract-call? .CarbonVote update-voting-power)
```

## Contract Functions

### Public Functions

#### `create-proposal`
Creates a new carbon reduction or green energy proposal.
- **Parameters**: title, description, target-reduction, energy-type
- **Requirements**: Minimum 1 STX balance, valid target reduction > 0
- **Returns**: Proposal ID

#### `vote`
Vote on an active proposal.
- **Parameters**: proposal-id, vote-yes (boolean)
- **Requirements**: Minimum 1 STX balance, no previous vote, voting period active
- **Returns**: Success boolean

#### `execute-proposal`
Execute a passed proposal after voting ends.
- **Parameters**: proposal-id
- **Requirements**: Voting period ended, proposal passed, not already executed
- **Returns**: Success boolean

#### `update-voting-power`
Update caller's voting power based on current STX balance.
- **Parameters**: None
- **Returns**: Updated voting power

### Read-Only Functions

#### `get-proposal`
Retrieve proposal details by ID.

#### `get-user-vote`
Get a user's vote on a specific proposal.

#### `get-voting-power`
Get voting power for a user.

#### `get-proposal-count`
Get total number of proposals created.

#### `get-total-carbon-reduction`
Get cumulative carbon reduction target from executed proposals.

#### `has-proposal-passed`
Check if a proposal has passed.

#### `get-proposal-status`
Get proposal status: "active", "passed", "rejected", or "not-found".

#### `get-voting-stats`
Get detailed voting statistics for a proposal.

## Deployment Guide

### Local Development
1. Start local Stacks blockchain:
```bash
clarinet integrate
```

2. Deploy contract:
```bash
clarinet deploy --devnet
```

### Testnet Deployment
1. Configure testnet in `Clarinet.toml`
2. Deploy to testnet:
```bash
clarinet deploy --testnet
```

### Mainnet Deployment
1. Configure mainnet settings
2. Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

## Error Codes

- `ERR_UNAUTHORIZED (100)`: Caller not authorized
- `ERR_PROPOSAL_NOT_FOUND (101)`: Proposal does not exist
- `ERR_ALREADY_VOTED (102)`: User has already voted on this proposal
- `ERR_VOTING_ENDED (103)`: Voting period has ended
- `ERR_VOTING_NOT_ENDED (104)`: Voting period has not ended yet
- `ERR_INVALID_PROPOSAL (105)`: Invalid proposal data or state
- `ERR_INSUFFICIENT_BALANCE (106)`: Insufficient STX balance for voting

## Security Considerations

### Access Control
- Proposal creation requires minimum STX balance
- Voting requires minimum STX balance
- No administrative functions beyond contract owner constant

### Vote Integrity
- One vote per user per proposal enforced by mapping constraints
- Voting power snapshot taken at vote time
- Immutable vote records on blockchain

### Proposal Execution
- Proposals can only be executed after voting period ends
- Proposals must have more YES than NO votes to pass
- Proposals can only be executed once

### Potential Risks
- **Plutocracy**: Higher STX holders have more voting power
- **Timing Attacks**: Proposals could be influenced by coordinated voting near deadline
- **Sybil Resistance**: Relies on STX token distribution for sybil resistance

## Development

### Running Tests
```bash
clarinet test
```

### Code Coverage
```bash
clarinet test --coverage
```

### Local Console
```bash
clarinet console
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is open source. Please check the LICENSE file for details.

## Contact

For questions, issues, or contributions, please open an issue on the repository or contact the development team.