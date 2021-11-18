Deployed at (polygon mumbai):
- ALPHA Token (ERC20): 0x4997910AC59004383561Ac7D6d8a65721Fa2A663
- BentoBoxV1: 0xFB015E3efDaE8F3b43151fFFEF383Ee724488f6B
- HelloBentoBox: 0x8eCa8FEBFd888F0C6ad06e2a7E2F0040912aE465


Depositing Money to HelloBentoBox from token:
  - when setting up contracts:
    - on BentoBoxV1 contract: whitelistMasterContract(helloBentoBox.address, true)
  1. on ALPHA Token contract: approve(bento.address, <max transferable amount per transaction>)
  2. on BentoBoxV1 contract: setMasterContractApproval(yourwallet.address, helloBentoBox.address, true)
  3. on HelloBentoBox contract: depositToHelloBentoBox(alphaToken.address, amount, false)

Withdrawing Money to HelloBentoBox from token:
  - on HelloBentoBox contract: withdrawFromHelloBentoBox(depositId, amount, true/false <transfering from your account to bentobox?>)
    - caveat: you can do withdrawals only by depositId. i.e. if you deposit 1000 (id = 0) and then 750 (id = 1), you can withdraw up to 1000 on id = 0 and up to 750 on id = 1, but not up to 1750 at once