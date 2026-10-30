function nfail = run_all_tests(seed)
%RUN_ALL_TESTS  Run every tests/test_*.m and report. Exits non-zero on failure
%   when run non-interactively (CI). SEED (default 1234) seeds the RNG
%   before each test.
if nargin < 1
    seed = 1234;
end
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));
addpath(here);
files = dir(fullfile(here, 'test_*.m'));
nfail = 0;
t_all = tic;
for i = 1:numel(files)
    name = files(i).name(1:end-2);
    rng(seed);                         % every test is reproducible on its own
    t0 = tic;
    try
        feval(name);
        fprintf('PASS  %-32s %6.2f s\n', name, toc(t0));
    catch err
        nfail = nfail + 1;
        fprintf('FAIL  %-32s %s\n', name, err.message);
        for s = 1:numel(err.stack)
            fprintf('        at %s:%d\n', err.stack(s).name, err.stack(s).line);
        end
    end
end
fprintf('\n%d tests, %d failed, %.1f s\n', numel(files), nfail, toc(t_all));
end
