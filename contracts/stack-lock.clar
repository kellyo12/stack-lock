(define-map locks  
  { user: principal }  
  {    
    amount: uint,    
    unlock-block: uint  
  }
)

(define-public (lock-stx (amount uint) (unlock-block uint))
  (let (
    (sender tx-sender)
  )
    (begin
      ;; Require non-zero amount
      (asserts! (> amount u0) (err u100))
      ;; Require future unlock block
      (asserts! (> unlock-block stacks-block-height) (err u101))
      ;; Check if user already has a lock
      (asserts! (is-none (map-get? locks { user: sender })) (err u104))
      ;; Transfer STX from sender to contract
      (try! (stx-transfer? amount sender (as-contract tx-sender)))
      ;; Save lock info
      (map-set locks { user: sender } {
        amount: amount,
        unlock-block: unlock-block
      })
      (ok true)
    )
  )
)

(define-public (withdraw)
  (let (
    (sender tx-sender)
    (lock (map-get? locks { user: sender }))
  )
    (match lock data
      (begin
        ;; Check if unlock block has been reached
        (asserts! (>= stacks-block-height (get unlock-block data)) (err u102))
        (let ((amount (get amount data)))
          ;; Remove lock first
          (map-delete locks { user: sender })
          ;; Transfer STX back to user
          (as-contract (stx-transfer? amount tx-sender sender))
        )
      )
      (err u103) ;; No lock found
    )
  )
)

(define-read-only (get-lock (user principal))
  (map-get? locks { user: user })
)

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)

