//Individual option struct
struct Option{
    name: String; 
    price: Int;
    pool: Int;
}

//Array to hold the options array
struct OptionsArray {
    m: map<Int, Option>;
    length: Int = 0;
}

const MaxArraySize: Int = 5_000;

//Append method to add element(option) in the array
extends mutates fun append(self: OptionsArray, item: Option) {
    require(self.length + 1 <= MaxArraySize, "No space in the array left for new items!");
    self.m.set(self.length, item); 
    self.length += 1;               
}

struct OptionDetail {
    name: String;  // Name of the option
    price: Int;    // Price of the option
}

struct BetDetails {
    totalPool: Int;                     // Total pool amount
    options: map<Int, OptionDetail>;    // Map of options and their prices
}



