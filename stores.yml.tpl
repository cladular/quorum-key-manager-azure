- kind: Store
  type: secret
  name: secrets
  specs:
    vault: az-key-vault

- kind: Store
  type: key
  name: keys
  specs:
    vault: az-key-vault

- kind: Store
  type: ethereum
  name: accounts
  specs:
    key_store: keys