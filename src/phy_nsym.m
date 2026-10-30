function nsym = phy_nsym(mcs, psdu_bytes)
%PHY_NSYM  Number of DATA OFDM symbols: SERVICE(16) + PSDU + tail(6), padded.
nsym = ceil((16 + 8 * psdu_bytes + 6) / mcs.ndbps);
end
