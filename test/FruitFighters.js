const FruitFighters = artifacts.require("FruitFighters");
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

contract("FruitFighters", (accounts) => {
    let [alice, bob] = accounts;
    let contractInstance;

    beforeEach(async () => {
        contractInstance = await FruitFighters.new("Fruit Fighters", "FF", "ipfs://");
    })
    
    it("should be able to create a new fancy fighter", async () => {
        const result = await contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});

        assert.equal(result.receipt.status, true);
        assert.equal(result.logs[0].args.name, fighterNames[0]);    
    });
    

    it("should be able to create a new rare fighter", async () => {
        const result = await contractInstance.createRareFruitFighter(fighterNames[0], {
            from: alice, 
            value: web3.utils.toWei('0.5', 'ether')
        });
        
        assert.equal(result.receipt.status, true);
        assert.equal(result.logs[0].args.name, fighterNames[0]);
        
    });

    it("should be able to check if name is free", async () => {
        await contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});
        const isFirstNameFree = await contractInstance.isNameAvailable(fighterNames[0], {from: alice});
        const isSecondNameFree = await contractInstance.isNameAvailable(fighterNames[1], {from: alice});
        assert.equal(isFirstNameFree, false);
        assert.equal(isSecondNameFree, true);
    });

    it("should allow to change name", async () => {
        const createFersult = await contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});
        const tokenId = createFersult.logs[0].args.id;
        const result = await contractInstance.changeName(tokenId, fighterNames[1], {
            from: alice,
            value: web3.utils.toWei('0.01', 'ether')
        });

        assert.equal(result.logs[0].args.name, fighterNames[1]);
    });


    it("should not allow two fighters with same name", async () => {
        contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice});
        await shouldThrow(contractInstance.createFancyFruitFighter(fighterNames[0], {from: alice}));
    });

    it("should not allow to create exclusive fruit fighters not from behalf contract owner", async () => {
        await shouldThrow(contractInstance.createExclusiveFruitFighter(fighterNames[0], {from: bob}));
    });

    it("should allow to create exclusive fruit fighters from owner", async () => {
        const result = await contractInstance.createExclusiveFruitFighter(fighterNames[0], {from: alice});
        assert.equal(result.logs[0].args.tokenType.toNumber(), 3);
    });


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
