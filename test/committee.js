const helpers = require("./helpers.js")
const Etherand = artifacts.require("./Etherand.sol")
const CallForTester = artifacts.require("./lib/CallForTester.sol")

contract("Committee", (users) => {
  const committee = users[0]
  const noCommittee = users[1]
  const targetAddress = users[2]
  let subject

  before(async () => {
    subject = await Etherand.new()
  })

  describe("setCommittee", () => {
    describe("when sender is not committee", () => {
      it("reverts", async () => {
        await helpers.assertRevert(
          subject.setCommittee(targetAddress, { from: noCommittee })
        )
      })
    })

    describe("when sender is committee", () => {
      it("should change committee", async () => {
        const { logs } = await subject.setCommittee(targetAddress, {
          from: committee
        })

        assert.equal(logs.length, 1)
        assert.equal(logs[0].event, "SetCommittee")
        assert.equal(logs[0].args.committee, targetAddress)
        const newCommittee = await subject.committee()
        assert.equal(newCommittee, targetAddress)
      })
    })
  })
})

contract("callFor", (users) => {
  const committee = users[0]
  const noCommittee = users[1]
  const targetAddress = users[2]
  let subject, targetContract, validInputs

  before(async () => {
    subject = await Etherand.new()
    targetContract = await CallForTester.new()
    await targetContract.setOwner(subject.address)
    validInputs = [
      targetContract.address,
      60000,
      targetContract.contract.methods.setOwner(targetAddress).encodeABI()
    ]
  })

  describe("when sender is not committee", () => {
    it("reverts", async () => {
      await helpers.assertRevert(
        subject.callFor(...validInputs, { from: noCommittee })
      )
    })
  })

  describe("when sender is committee", () => {
    it("should work", async () => {
      await subject.callFor(...validInputs, { from: committee })

      const owner = await targetContract.owner()
      expect(owner).to.equal(targetAddress)
    })
  })
})
