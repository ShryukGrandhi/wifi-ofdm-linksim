function k = qam_norm(nbpsc)
%QAM_NORM  Scale factor giving unit average symbol energy (802.11a K_MOD).
switch nbpsc
    case 1, k = 1;
    case 2, k = 1 / sqrt(2);
    case 4, k = 1 / sqrt(10);
    case 6, k = 1 / sqrt(42);
    otherwise
        error('qam_norm:nbpsc', 'unsupported bits per symbol %d', nbpsc);
end
end
