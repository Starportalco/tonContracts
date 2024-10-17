message BuyShares {
    optionIndex: Int;
    betAmount: Int;
}

message SellShares{
    optionIndex: Int;
    shareAmount: Int;
}

message AddOption{
    optionName: String;
    initialPrice: Int;
}

message DeclareWinner{
    optionIndex: Int;
}

message ClaimWinnings{
    
}