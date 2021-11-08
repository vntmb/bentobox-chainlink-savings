import * as React from 'react'
import Avatar from '@mui/material/Avatar';
import Button from '@mui/material/Button';
import CssBaseline from '@mui/material/CssBaseline';
import TextField from '@mui/material/TextField';
import Box from '@mui/material/Box';
import LockOutlinedIcon from '@mui/icons-material/LockOutlined';
import Typography from '@mui/material/Typography';
import Container from '@mui/material/Container';
import DownloadIcon from '@mui/icons-material/Download';

import Grid from '@mui/material/Grid';

const SavingsDeposit = () => {

    const onDepositClick = () => {
        console.log("deposit clicked!!");
    };

    const onWithdrawClick = () => {
        console.log("withdraw clicked!!");
    };

    return (
        <div>
            <Grid container justifyContent="center">
                <Grid item xs={4}>
                    <Container component="main">
                        <CssBaseline />
                        <Box component="form" onSubmit={onDepositClick}
                            sx={{
                                marginTop: 8,
                                display: 'flex',
                                flexDirection: 'column',
                                alignItems: 'center',
                            }}
                        >
                            <Avatar sx={{ m: 1, bgcolor: 'primary.main' }}>
                                <LockOutlinedIcon />
                            </Avatar>
                            <Typography component="h1" variant="h5">
                                Deposit Tokens
                            </Typography>
                            <TextField
                                margin="normal"
                                required
                                fullWidth
                                id="token"
                                label="Token Address"
                                name="token"
                                autoComplete="token"
                                autoFocus
                            />
                            <TextField
                                margin="normal"
                                required
                                fullWidth
                                name="amount"
                                label="Amount"
                                type="number"
                                id="amount"
                                autoComplete="current-amount"
                            />
                            <Button
                                type="submit"
                                fullWidth
                                variant="contained"
                                sx={{ mt: 3, mb: 2 }}
                            >
                                Deposit
                            </Button>
                        </Box>
                    </Container>
                </Grid>
                <Grid item xs={4}>
                    <Container component="main">
                        <CssBaseline />
                        <Box component="form" onSubmit={onWithdrawClick}
                            sx={{
                                marginTop: 8,
                                display: 'flex',
                                flexDirection: 'column',
                                alignItems: 'center',
                            }}
                        >
                            <Avatar sx={{ m: 1, bgcolor: 'primary.main' }}>
                                <DownloadIcon />
                            </Avatar>
                            <Typography component="h1" variant="h5">
                                Withdraw Tokens
                            </Typography>
                            <TextField
                                margin="normal"
                                required
                                fullWidth
                                id="token"
                                label="Token Address"
                                name="token"
                                autoComplete="token"
                                autoFocus
                            />
                            <TextField
                                margin="normal"
                                required
                                fullWidth
                                name="amount"
                                label="Amount"
                                type="number"
                                id="amount"
                                autoComplete="current-amount"
                            />
                            <Button
                                type="submit"
                                fullWidth
                                variant="contained"
                                sx={{ mt: 3, mb: 2 }}
                            >
                                Withdraw
                            </Button>
                        </Box>
                    </Container>
                </Grid>
            </Grid>
            {/* <Container component="main" maxWidth="xs">
                <CssBaseline />
                <Box component="form" onSubmit={onDepositClick}
                    sx={{
                        marginTop: 8,
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                    }}
                >
                    <Avatar sx={{ m: 1, bgcolor: 'primary.main' }}>
                        <LockOutlinedIcon />
                    </Avatar>
                    <Typography component="h1" variant="h5">
                        Deposit Tokens
                    </Typography>
                    <TextField
                        margin="normal"
                        required
                        fullWidth
                        id="token"
                        label="Token Address"
                        name="token"
                        autoComplete="token"
                        autoFocus
                    />
                    <TextField
                        margin="normal"
                        required
                        fullWidth
                        name="amount"
                        label="Amount"
                        id="amount"
                        autoComplete="current-amount"
                    />
                    <Button
                        type="submit"
                        fullWidth
                        variant="contained"
                        sx={{ mt: 3, mb: 2 }}
                    >
                        Deposit
                    </Button>
                </Box>
            </Container> */}
        </div>
    )
}
export default SavingsDeposit

