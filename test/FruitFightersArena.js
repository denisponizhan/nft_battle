const FruitFightersArena = artifacts.require("FruitFightersArena");
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

contract("FruitFightersArena", (accounts) => {
    let [alice, bob] = accounts;
    let contractInstance;

    beforeEach(async () => {
        contractInstance = await FruitFightersArena.new();
    })

    it("should be able to allow to enter arena with a valid bid", async () => {
        const result = await contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});
        const tokenId = result.logs[0].args.id;

        await contractInstance.enterArena(tokenId, {
            from: alice, 
            value: web3.utils.toWei('0.01', 'ether')
        });
    })

    it("should not allow to enter arena twice with same tokenId", async () => {
        const result = await contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});
        const tokenId = result.logs[0].args.id;

        await contractInstance.enterArena(tokenId, {
            from: alice, 
            value: web3.utils.toWei('0.01', 'ether')
        });

        await shouldThrow(contractInstance.enterArena(tokenId, {
            from: alice, 
            value: web3.utils.toWei('0.01', 'ether')
        }));
    })
    
    it("should not allow to enter arena with foreign token", async () => {
        const result = await contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});
        const tokenId = result.logs[0].args.id;

        await shouldThrow(contractInstance.enterArena(tokenId, {
            from: bob, 
            value: web3.utils.toWei('0.1', 'ether')
        }));
    })

    it("should not allow to enter arena with bid that less minimal bid", async () => {
        const result = await contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});
        const tokenId = result.logs[0].args.id;

        await shouldThrow(contractInstance.enterArena(tokenId, {
            from: alice, 
            value: web3.utils.toWei('0.0001', 'ether')
        }));
    })

    it("should be able to allow to fight with another fighter", async () => {
        const result = await contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});
        const result1 = await contractInstance.createFancyFruitFighter(fighterNames[1], {from: bob});
        
        const tokenId = result.logs[0].args.id;
        const targetId = result1.logs[0].args.id;

        await contractInstance.enterArena(tokenId, {
            from: alice, 
            value: web3.utils.toWei('0.01', 'ether')
        });

        const fightResult = await contractInstance.fight(targetId, tokenId, {
            from: bob, 
            value: web3.utils.toWei('0.01', 'ether')
        });

        assert.equal(fightResult.receipt.status, true);
    });

    it("should not allow to fight with fighter not in area", async () => {
        const result = await contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});
        const result1 = await contractInstance.createFancyFruitFighter(fighterNames[1], {from: bob});
        
        const tokenId = result.logs[0].args.id;
        const targetId = result1.logs[0].args.id;

        await shouldThrow(contractInstance.fight(targetId, tokenId, {
            from: bob, 
            value: web3.utils.toWei('0.01', 'ether')
        }));
    })

    it("should not allow to fight with himself", async () => {
        const result = await contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});
        const tokenId = result.logs[0].args.id;

        await shouldThrow(contractInstance.fight(tokenId, tokenId, {
            from: alice, 
            value: web3.utils.toWei('0.01', 'ether')
        }));
    })

    it("should allow to withdraw a reward after fighting", async () => {
        const result = await contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});
        const result1 = await contractInstance.createFancyFruitFighter(fighterNames[1], {from: bob});
        
        const tokenId = result.logs[0].args.id;
        const targetId = result1.logs[0].args.id;

        await contractInstance.enterArena(tokenId, {
            from: alice, 
            value: web3.utils.toWei('0.01', 'ether')
        });

        const fightResult = await contractInstance.fight(targetId, tokenId, {
            from: bob, 
            value: web3.utils.toWei('0.01', 'ether')
        });

        const winOwner = fightResult.logs[0].args.owner;

        const withdrawResult = await contractInstance.withdraw({
            from: winOwner
        })

        assert.equal(withdrawResult.receipt.status, true);
    })
})
