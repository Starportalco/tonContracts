import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages";
import "./utils";

contract BetsParentContract with Deployable, Ownable {
    totalPool : Int;
    owner: Address;            
    options: OptionsArray;     
    description: String;      
    winnerDeclared: Bool = false; 
    userShares: map<Address, Int>;

    init(
        _description: String,
        option1Name: String,
        option1Pool: Int, 
        option2Name: String, 
        option2Pool: Int
    ) {
        self.owner = sender(); 
        self.description = _description;

        self.options = OptionsArray{m: emptyMap(), length: 0};

        self.totalPool = option1Pool + option2Pool; 

        let option1 = Option{ 
            name: option1Name, 
            price: self.totalPool != 0 ? option1Pool / self.totalPool : 0, 
            pool: option1Pool 
        };
        self.options.append(option1); 

        let option2 = Option{ 
            name: option2Name, 
            price: self.totalPool != 0 ? option2Pool / self.totalPool : 0, 
            pool: option2Pool 
        };
        self.options.append(option2); 
    }

    //Getter function to get the contract Balance
    get fun contractBalance(): String{
        return myBalance().toCoinsString();
    }

    fun updatePrices(){          
        foreach (index, option in self.options.m) {
            option.price = option.pool / self.totalPool; 
            self.options.m.set(index, option); // Update the option with the new price
        }
    }

    get fun getEffectivePrice(optionIndex: Int, betAmount: Int): Int {
        let currentPrice: Int = self.options.m.get(optionIndex)!!.price;
        let newPrice: Int = (self.options.m.get(optionIndex)!!.pool - betAmount) / (self.totalPool - betAmount);
        let effectivePrice: Int = (currentPrice + newPrice) / 2;
        return effectivePrice;
    }

    get fun userHoldings(address: Address): Int?{
        let holdings: Int? = self.userShares.get(address);
        if(holdings == null){
            return null;
        }
        let userShares: Int =  self.userShares.get(address)!!;
        return userShares;
    }

    receive(msg: BuyShares) {
        require(msg.optionIndex < self.options.length, "Invalid option");
        require(!self.winnerDeclared, "Winner already declared");
        require(self.totalPool > 0, "Liquidity must be added before placing bets");

        let option: Option = self.options.m.get(msg.optionIndex)!!; 
        option.pool += msg.betAmount;

        self.totalPool += msg.betAmount;

        self.updatePrices();

        let effectivePrice: Int = self.getEffectivePrice(msg.optionIndex, msg.betAmount);    
        
        let sharesBought: Int = msg.betAmount / effectivePrice;

        let key: Address = sender();
        let currentShares: Int? = self.userShares.get(key);

        if (currentShares == null) {
            self.userShares.set(key, sharesBought); 
        } else {
            let currentSharesAsInt: Int = self.userShares.get(key)!!;
            self.userShares.set(key, currentSharesAsInt + sharesBought); 
        }
    }

    receive(msg: SellShares){
        require(optionIndex < self.options.length, "Invalid option");
        require(!self.winnerDeclared, "Winner already declared");

        // Check if the user has sufficient shares
        let key: Address = sender();
        let currentShares: Int? = self.userShares.get(key); 
        require(currentShares != null && currentShares >= shareAmount, "Insufficient shares");
    }
}
