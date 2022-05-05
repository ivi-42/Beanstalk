/**
 * SPDX-License-Identifier: MIT
**/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./SiloExit.sol";
import "../../../libraries/Silo/LibSilo.sol";
import "../../../libraries/Silo/LibTokenSilo.sol";
import "hardhat/console.sol";

/**
 * @author Publius
 * @title Silo Entrance
**/
contract Silo is SiloExit {

    using SafeMath for uint256;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status = 1;

    /**
     * Update
    **/

    function update(address account) public payable {
        uint32 _update = lastUpdate(account);
        if (_update >= season()) return;
        earnSops(account, _update);
        earnGrownStalk(account);
        s.a[account].lastUpdate = season();
    }

    function earn(address account) external payable {
        update(account);
        uint256 accountStalk = s.a[account].s.stalk;
        uint256 beans = _balanceOfEarnedBeans(account, accountStalk);
        if (beans == 0) return;
        s.earnedBeans = s.earnedBeans.sub(beans);
        uint256 seeds = beans.mul(C.getSeedsPerBean());
        LibSilo.incrementBalanceOfSeeds(account, seeds);
        s.a[account].s.stalk = accountStalk.add(beans.mul(C.getStalkPerBean()));
        LibTokenSilo.addDeposit(account, C.beanAddress(), season(), beans, beans.mul(C.getStalkPerBean()));
    }

    function earnGrownStalk(address account) private {
        if (s.a[account].s.seeds == 0) return;
        LibSilo.incrementBalanceOfStalk(account, balanceOfGrownStalk(account));
    }

    function earnSops(address account, uint32 _update) internal {
        // If no roots, reset Sop counters variables
        if (s.a[account].roots == 0) {
            s.a[account].lastSop = s.r.start;
            s.a[account].lastRain = 0;
            return;
        }
        // If a Sop has occured since last update, calculate rewards and set last Sop.
        if (s.season.lastSopSeason > _update) {
            s.a[account].sop.plenty = balanceOfPlenty(account);
            s.a[account].lastSop = s.season.lastSop;
        }
        if (s.r.raining) {
            // If rain started after update, set account variables to track rain.
            if (s.r.start > _update) {
                s.a[account].lastRain = s.r.start;
                s.a[account].sop.roots = s.a[account].roots;
            }
            // If there has been a Sop since rain started,
            // save plentyPerRoot in case another SOP happens during rain.
            if (s.season.lastSop == s.r.start) s.a[account].sop.plentyPerRoot = s.sops[s.season.lastSop];
        } else if (s.a[account].lastRain > 0) {
            // Reset Last Rain if not raining.
            s.a[account].lastRain = 0;
        }
    }

    modifier updateSilo() {
        update(msg.sender);
        _;
    }
}
