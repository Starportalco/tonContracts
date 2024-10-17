import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages";
import "./utils";

const PRECISION: Int = pow(10, 2); //Precision to work with floating point values...

contract BetsParentContract with Deployable, Ownable {
    id: Int as uint32;
    totalPool : Int;
    owner: Address;            
    options: OptionsArray;     
    description: String;      
    winnerDeclared: Bool = false; 
    winningOptionIndex: Int = 0; 
    userShares: map<Address, Int>;

    init(
        id: Int,
        _description: String,
        option1Name: String,
        option1Pool: Int, 
        option2Name: String, 
        option2Pool: Int
    ) {
        self.id = id;
        self.owner = sender(); 
        self.description = _description;

        self.options = OptionsArray{m: emptyMap(), length: 0};

        self.totalPool = option1Pool + option2Pool; 

        let option1 = Option{ 
            name: option1Name, 
            price: (option1Pool * PRECISION) / self.totalPool, 
            pool: option1Pool 
        };
        self.options.append(option1); 
        dump(option1.price);
        let option2 = Option{ 
            name: option2Name, 
            price: (option2Pool * PRECISION) / self.totalPool, 
            pool: option2Pool 
        };
        self.options.append(option2);
        dump(option2.price); 
    }

    receive(){
        // accept incoming TON transfers
    }


    //Getter function to get the contract Balance
    get fun contractBalance(): Int{
        return myBalance();
    }

    get fun updatePrices(){          
        foreach (index, option in self.options.m) {
            option.price = (option.pool * PRECISION) / self.totalPool;
            self.options.m.set(index, option); // Update the option with the new price
        }
    }

    get fun EffectivePrice(optionIndex: Int, betAmount: Int): Int {
        let currentPrice: Int = self.options.m.get(optionIndex)!!.price;
        let newPrice: Int = ((self.options.m.get(optionIndex)!!.pool + betAmount) * PRECISION) / (self.totalPool + betAmount);
        let effectivePrice: Int = (currentPrice + newPrice) / 2;
        return effectivePrice;
    }

    get fun userHoldings(address: Address): Int{
        let holdings: Int? = self.userShares.get(address);
        if(holdings == null){
            return 0;
        }
        let userShares: Int =  self.userShares.get(address)!!;
        return userShares;
    }

    fun addLiquidity(liquidity: Int){
        self.requireOwner();
        self.totalPool += liquidity;
        
        foreach (index, option in self.options.m) {
            let poolShare: Int = (option.price * self.totalPool) / PRECISION; 
            option.pool = poolShare; 
            self.options.m.set(index, option); 
        }

        self.updatePrices();
    } 

    // Getter function to for betDetails
    get fun BetDetails(): BetDetails {
        let betDetails  = BetDetails{totalPool: self.totalPool, options: emptyMap()};
        
        foreach (index, option in self.options.m) {
            betDetails.options.set(index, OptionDetail{
                name: option.name,
                price: option.price
            }); 
        }
        return betDetails; 
    }


    receive(msg: BuyShares) {
        require(msg.optionIndex < self.options.length, "Invalid option");
        require(!self.winnerDeclared, "Winner already declared");
        require(self.totalPool > 0, "Liquidity must be added before placing bets");

        let option: Option = self.options.m.get(msg.optionIndex)!!; 
        option.pool += msg.betAmount;

        self.totalPool += msg.betAmount;

        self.updatePrices();

        let effectivePrice: Int = self.EffectivePrice(msg.optionIndex, msg.betAmount);    
        
        let sharesBought: Int = (msg.betAmount * PRECISION) / effectivePrice;

        let key: Address = sender();
        let currentShares: Int? = self.userShares.get(key);

        if (currentShares == null) {
            self.userShares.set(key, sharesBought); 
        } else {
            self.userShares.set(key, currentShares!! + sharesBought); 
        }
    }

    receive(msg: SellShares){
        require(msg.optionIndex < self.options.length, "Invalid option");
        require(!self.winnerDeclared, "Winner already declared");

        // Check if the user has sufficient shares
        let key: Address = sender();
        let currentShares: Int? = self.userShares.get(key); 
        require(currentShares != null && currentShares!! >= msg.shareAmount, "Insufficient shares");

        let currentPrice: Int = self.options.m.get(msg.optionIndex)!!.price;
        let poolReduction: Int = (msg.shareAmount * currentPrice) / PRECISION;

        let optionPool: Int = self.options.m.get(msg.optionIndex)!!.pool;
        let newOptionPool: Int = optionPool > poolReduction ? optionPool - poolReduction : 1;

        let totalPoolBefore: Int = self.totalPool;
        let newTotalPool: Int = totalPoolBefore > poolReduction ? totalPoolBefore - poolReduction : 1;

        let newPrice: Int = (newOptionPool * PRECISION) / newTotalPool;
        let effectivePrice: Int = (currentPrice + newPrice) / 2;

        // Calculate the value of the shares being sold based on the effective price
        let sellValue: Int = (msg.shareAmount * effectivePrice) / PRECISION;

        // Update the option's pool and the total pool
        newOptionPool = self.options.m.get(msg.optionIndex)!!.pool;
        self.totalPool = newTotalPool;

        // Recalculate prices for all options
        self.updatePrices();

        // Deduct the user's shares
        self.userShares.set(key, currentShares!! - msg.shareAmount); // Update the user's shares

        send(SendParameters{
            to: sender(),
            value: sellValue,
            mode: SendIgnoreErrors,
            body: "Amount send for selling the shares".asComment(),
        });
    }

    receive(msg: AddOption){
        self.requireOwner();
        require(!self.winnerDeclared, "Cannot add options after the winner has been declared");
        require(msg.initialPrice > 0 && msg.initialPrice < PRECISION, "Initial price must be between 0 and 1 (in 6 decimals)");

        let reductionFactor: Int = (PRECISION - msg.initialPrice) * PRECISION / PRECISION;

        foreach (index, option in self.options.m) {
            option.price = (option.price * reductionFactor) / PRECISION; 
            option.pool = (option.pool * reductionFactor) / PRECISION;   
            self.options.m.set(index, option); 
        }

        let newOption = Option{
            name: msg.optionName,
            price: msg.initialPrice,
            pool: 0
        };
        self.options.append(newOption);

        let remainingPool: Int = self.totalPool;
        foreach (index, option in self.options.m) {
            option.pool = (option.price * self.totalPool) / PRECISION; // Update pool
            remainingPool -= option.pool; // Subtract from remaining pool
            self.options.m.set(index, option); // Update the option in the map
        }

        if (remainingPool > 0) {
            let lastOption: Option = self.options.m.get(self.options.length - 1)!!; // Get last option
            lastOption.pool += remainingPool; // Add remaining pool to last option
            self.options.m.set(self.options.length - 1, lastOption); // Update last option
        }

        self.updatePrices();
    }

    receive(msg: DeclareWinner) {
        self.requireOwner(); // Only the owner can declare the winner
        require(msg.optionIndex < self.options.length, "Invalid option");
        require(!self.winnerDeclared, "Winner already declared");

        self.winningOptionIndex = msg.optionIndex;
        self.winnerDeclared = true;
    }

    receive(msg: ClaimWinnings) {
        require(self.winnerDeclared, "Winner not declared yet");

        let userSharesInWinningOption: Int? = self.userShares.get(sender());
        require(userSharesInWinningOption != null && userSharesInWinningOption!! > 0, "No shares in winning option");

        let winnings: Int = (userSharesInWinningOption!! * self.totalPool) / self.options.m.get(self.winningOptionIndex)!!.pool;

        self.userShares.set(sender(), 0); // Reset the user's shares in the winning option

        send(SendParameters{
            to: sender(),
            value: winnings,
            mode: SendIgnoreErrors,
            body: "Winnings claimed".asComment(),
        });
    }
}
