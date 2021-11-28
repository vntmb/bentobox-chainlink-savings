Deployed at (polygon mumbai):
- ALPHA Token (ERC20): 0x4997910AC59004383561Ac7D6d8a65721Fa2A663
- BETA Token (ERC20): 0xd5936853145A0212AA86BeDc434F8365f84069D5
- VARIETY Token (ERC20): 0x98C50fa9f048E8F452d32B8dE8E96c0b14642B9F


- BentoBoxV1: 0x7fF4AF5118B196743B461b8C3Ce7964CF77e6734
- VarietySavings: 0x3A76632723762BABC1cB36037A5aB880b45d3a1F
- VarietySavingsDAO: 0xA40FC81BAB78d5E4A9e27Cc6f91d11638CF4fCa0


Depositing Money to VarietySavings from token:
  - when setting up contracts:
    - on BentoBoxV1 contract: whitelistMasterContract(VarietySavings.address, true)
  1. on ALPHA Token contract: approve(bento.address, max transferable amount per transaction)
  2. on VarietySavings contract: setBentoBoxApproval(yourwallet.address, true)
  3. on VarietySavings contract: depositToVarietySavings(alphaToken.address, amount, false)

Withdrawing Money to VarietySavings from token:
  - on VarietySavings contract: withdrawFromVarietySavings(depositId, amount, true/false <transfering from your account to bentobox?>)
    - caveat: you can do withdrawals only by depositId. i.e. if you deposit 1000 (id = 0) and then 750 (id = 1), you can withdraw up to 1000 on id = 0 and up to 750 on id = 1, but not up to 1750 at once
