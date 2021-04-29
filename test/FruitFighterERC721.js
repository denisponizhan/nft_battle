const FruitFighterERC721 = artifacts.require("FruitFighterERC721");
const fighterNames = ["King", "Qeen", "Rocky"];

async function shouldThrow(promise) {
    try {
        await promise;
        assert(true);
    } catch (err) {
        return;
    }
    assert(false, "The contract did not throw.");   
}    

contract("FruitFighterERC721", (accounts) => {
    let [alice, bob] = accounts;
    let contractInstance;

    beforeEach(async () => {
        contractInstance = await FruitFighterERC721.new("Fruit Fighter", "FF", "ipfs://");
    });

    it("should be able to transfer Fruit Fighter ERC721", async () => {
        const result = await contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});
        const tokenId = result.logs[0].args.id;
        await contractInstance.safeTransferFrom(alice, bob, tokenId, {from: alice});
        const newOwner = await contractInstance.ownerOf(tokenId);
        assert.equal(newOwner, bob);
    });

    it("should approve and then transfer a Fruit Fighter ERC721 when the approved address calls transferFrom", async () => {
        const result = await contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});
        const tokenId = result.logs[0].args.id;
        await contractInstance.approve(bob, tokenId, {from: alice});
        await contractInstance.safeTransferFrom(alice, bob, tokenId, {from: bob});
        const newOwner = await contractInstance.ownerOf(tokenId);
        assert.equal(newOwner, bob);
    });
    
    it("should approve and then transfer a Fruit Fighter ERC721 when the owner calls transferFrom", async () => {
        const result = await contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});
        const tokenId = result.logs[0].args.id;
        await contractInstance.approve(bob, tokenId, {from: alice});
        await contractInstance.safeTransferFrom(alice, bob, tokenId, {from: alice});
        const balanceOfNewOwner = await contractInstance.balanceOf(bob);
        assert.equal(balanceOfNewOwner, 1);
    });
})
