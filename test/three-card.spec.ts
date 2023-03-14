import { EthersError, formatUnits, parseUnits } from 'ethers';
import { MyTokenInstance, ThreeCardsInstance } from '../types/truffle-contracts';

const MyToken = artifacts.require('MyToken');
const ThreeCards = artifacts.require('ThreeCards');

contract('[feature] 3-cards game', function (accounts) {
  const banker = accounts[0];
  const dealer = accounts[1];
  const peter = accounts[2];
  const jack = accounts[3];
  let token: MyTokenInstance;
  let tokenDecimals: number;
  let game: ThreeCardsInstance;

  /**
   * Reusable methods
   */
  async function printState(address: string, sender: string, name: string) {
    const instance = await ThreeCards.at(address);
    console.log(`==========${name} stage view==========`);
    const currentPot = await instance.pot({ from: sender });
    const currentBet = await instance.getBet({ from: sender });
    console.log('Current Pot:', formatUnits(currentPot.toString(), tokenDecimals));
    console.log(`Current ${name}'s Bet:`);
    console.log('$$', formatUnits(currentBet.betAmount.toString(), tokenDecimals));
    console.log('cards:', currentBet.cards);
    console.log(`==========${name} stage view==========`);
  }

  async function newGame(): Promise<ThreeCardsInstance> {
    const minBet = parseUnits('1', tokenDecimals).toString();
    const maxBet = parseUnits('100', tokenDecimals).toString();
    return ThreeCards.new(token.address, minBet, maxBet, { from: dealer });
  }

  async function printBalance(address: string, name: string) {
    const balance = await token.balanceOf(address, { from: address });
    console.log(`${name} balance:`, formatUnits(balance.toString(), tokenDecimals));
  }

  /** Banker sells chips */
  before('Should buy chips from banker', async function () {
    token = await MyToken.new({ from: banker });
    tokenDecimals = (await token.decimals()).toNumber();
    const chips = parseUnits('1000', tokenDecimals).toString();
    await token.mint(peter, chips, { from: banker });
    await token.mint(jack, chips, { from: banker });
  });

  it('success deploy a game', async function () {
    /** Dealer new a game */
    game = await newGame();
  });

  it('success playing bets', async function () {
    /** Peter places bet */
    const peterBet = parseUnits('2', tokenDecimals).toString();
    /** Pre-flight, approve amount step */
    await token.approve(game.address, peterBet, { from: peter });
    await game.buyIn(peterBet, { from: peter });
    await printState(game.address, peter, 'Peter');

    /** Jack places bet */
    const jackBet = parseUnits('3', tokenDecimals).toString();
    /** Pre-flight, approve amount step */
    await token.approve(game.address, jackBet, { from: jack });
    await game.buyIn(jackBet, { from: jack });
    await printState(game.address, jack, 'Jack');
  });

  it('success show off', async function () {
    /** Dealer shows off */
    await game.showOff({ from: dealer });
  });

  it('Success withdraw', async function () {
    /** Peter withdrawn */
    try {
      await game.withdraw({ from: peter });
    } catch (e) {
      console.log('ERROR: Peter:', (e as EthersError).message);
    }
    await printBalance(peter, 'Peter');

    /** Jack withdrawn */
    try {
      await game.withdraw({ from: jack });
    } catch (e) {
      console.log('ERROR: Jack:', (e as EthersError).message);
    }
    await printBalance(jack, 'Jack');
  });
});
