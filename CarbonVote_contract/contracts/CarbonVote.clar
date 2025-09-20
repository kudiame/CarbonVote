
;; title: CarbonVote
;; version: 1.0.0
;; summary: Community governance system for emission reduction targets and green energy transitions
;; description: A decentralized voting platform where community members can propose and vote on emission reduction targets and green energy initiatives

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_VOTED (err u102))
(define-constant ERR_VOTING_ENDED (err u103))
(define-constant ERR_VOTING_NOT_ENDED (err u104))
(define-constant ERR_INVALID_PROPOSAL (err u105))
(define-constant ERR_INSUFFICIENT_BALANCE (err u106))

;; Voting duration in blocks (approximately 1 week = 1008 blocks at 10 min/block)
(define-constant VOTING_DURATION u1008)
(define-constant MIN_VOTING_POWER u1000000) ;; 1 STX in microSTX

;; data vars
(define-data-var proposal-counter uint u0)
(define-data-var total-carbon-reduction-target uint u0)

;; data maps
;; Proposals map: proposal-id -> proposal data
(define-map proposals uint {
    title: (string-ascii 100),
    description: (string-ascii 500),
    target-reduction: uint, ;; CO2 reduction target in tons
    energy-type: (string-ascii 50), ;; Type of green energy (solar, wind, hydro, etc.)
    proposer: principal,
    start-block: uint,
    end-block: uint,
    yes-votes: uint,
    no-votes: uint,
    total-voters: uint,
    executed: bool
})

;; Track user votes: proposal-id -> voter -> vote-data
(define-map votes {proposal-id: uint, voter: principal} {
    vote: bool, ;; true for yes, false for no
    voting-power: uint,
    block-height: uint
})

;; Track user voting power based on STX balance
(define-map user-voting-power principal uint)

;; public functions

;; Create a new proposal for carbon reduction or green energy initiative
(define-public (create-proposal
    (title (string-ascii 100))
    (description (string-ascii 500))
    (target-reduction uint)
    (energy-type (string-ascii 50)))
    (let ((proposal-id (+ (var-get proposal-counter) u1))
          (current-block block-height)
          (voting-power (get-voting-power tx-sender)))
        (asserts! (>= voting-power MIN_VOTING_POWER) ERR_INSUFFICIENT_BALANCE)
        (asserts! (> target-reduction u0) ERR_INVALID_PROPOSAL)
        (map-set proposals proposal-id {
            title: title,
            description: description,
            target-reduction: target-reduction,
            energy-type: energy-type,
            proposer: tx-sender,
            start-block: current-block,
            end-block: (+ current-block VOTING_DURATION),
            yes-votes: u0,
            no-votes: u0,
            total-voters: u0,
            executed: false
        })
        (var-set proposal-counter proposal-id)
        (ok proposal-id)))

;; Vote on a proposal
(define-public (vote (proposal-id uint) (vote-yes bool))
    (let ((proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
          (voting-power (get-voting-power tx-sender))
          (vote-key {proposal-id: proposal-id, voter: tx-sender}))
        (asserts! (>= voting-power MIN_VOTING_POWER) ERR_INSUFFICIENT_BALANCE)
        (asserts! (is-none (map-get? votes vote-key)) ERR_ALREADY_VOTED)
        (asserts! (<= block-height (get end-block proposal)) ERR_VOTING_ENDED)

        ;; Record the vote
        (map-set votes vote-key {
            vote: vote-yes,
            voting-power: voting-power,
            block-height: block-height
        })

        ;; Update proposal vote counts
        (if vote-yes
            (map-set proposals proposal-id
                (merge proposal {
                    yes-votes: (+ (get yes-votes proposal) voting-power),
                    total-voters: (+ (get total-voters proposal) u1)
                }))
            (map-set proposals proposal-id
                (merge proposal {
                    no-votes: (+ (get no-votes proposal) voting-power),
                    total-voters: (+ (get total-voters proposal) u1)
                })))
        (ok true)))

;; Execute a passed proposal (can only be called after voting period ends)
(define-public (execute-proposal (proposal-id uint))
    (let ((proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND)))
        (asserts! (> block-height (get end-block proposal)) ERR_VOTING_NOT_ENDED)
        (asserts! (not (get executed proposal)) ERR_INVALID_PROPOSAL)
        (asserts! (> (get yes-votes proposal) (get no-votes proposal)) ERR_INVALID_PROPOSAL)

        ;; Mark proposal as executed
        (map-set proposals proposal-id (merge proposal {executed: true}))

        ;; Add to total carbon reduction target if proposal passed
        (var-set total-carbon-reduction-target
            (+ (var-get total-carbon-reduction-target) (get target-reduction proposal)))

        (ok true)))

;; Update user voting power (should be called when user's STX balance changes)
(define-public (update-voting-power)
    (let ((balance (stx-get-balance tx-sender)))
        (map-set user-voting-power tx-sender balance)
        (ok balance)))

;; read only functions

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id))

;; Get user's vote on a specific proposal
(define-read-only (get-user-vote (proposal-id uint) (voter principal))
    (map-get? votes {proposal-id: proposal-id, voter: voter}))

;; Get voting power for a user
(define-read-only (get-voting-power (user principal))
    (default-to (stx-get-balance user) (map-get? user-voting-power user)))

;; Get current proposal counter
(define-read-only (get-proposal-count)
    (var-get proposal-counter))

;; Get total carbon reduction target achieved
(define-read-only (get-total-carbon-reduction)
    (var-get total-carbon-reduction-target))

;; Check if proposal has passed
(define-read-only (has-proposal-passed (proposal-id uint))
    (match (map-get? proposals proposal-id)
        proposal (and
            (> block-height (get end-block proposal))
            (> (get yes-votes proposal) (get no-votes proposal)))
        false))

;; Get proposal status
(define-read-only (get-proposal-status (proposal-id uint))
    (match (map-get? proposals proposal-id)
        proposal (if (> block-height (get end-block proposal))
            (if (> (get yes-votes proposal) (get no-votes proposal))
                "passed"
                "rejected")
            "active")
        "not-found"))

;; Get voting statistics for a proposal
(define-read-only (get-voting-stats (proposal-id uint))
    (match (map-get? proposals proposal-id)
        proposal (some {
            yes-votes: (get yes-votes proposal),
            no-votes: (get no-votes proposal),
            total-voters: (get total-voters proposal),
            participation-rate: (if (> (+ (get yes-votes proposal) (get no-votes proposal)) u0)
                (/ (* (get total-voters proposal) u100)
                   (/ (+ (get yes-votes proposal) (get no-votes proposal)) MIN_VOTING_POWER))
                u0)
        })
        none))

;; private functions
;;

