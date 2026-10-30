function state = scrambler_seed_from_service(first7)
%SCRAMBLER_SEED_FROM_SERVICE  Recover the scrambler state at the receiver.
%   The first 7 bits of the SERVICE field are zero before scrambling, so the
%   received (scrambled) bits equal the scrambler output. After seven shifts
%   the register holds exactly those bits, newest first. The returned state
%   continues descrambling from bit 8 onward.

first7 = first7(:);
if numel(first7) ~= 7
    error('scrambler_seed_from_service:len', 'need exactly 7 bits');
end
state = flipud(first7);
if ~any(state)
    % only possible after decoding errors (a valid seed is nonzero); keep
    % going so the packet is counted as an error rather than aborting
    state = ones(7, 1);
end
end
