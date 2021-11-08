import * as React from 'react'
import Avatar from '@mui/material/Avatar';
import Button from '@mui/material/Button';
import CssBaseline from '@mui/material/CssBaseline';
import TextField from '@mui/material/TextField';
import Box from '@mui/material/Box';
import LockOutlinedIcon from '@mui/icons-material/LockOutlined';
import Typography from '@mui/material/Typography';
import Container from '@mui/material/Container';

const SavingsDeposit = () => {

    const onDepositClick = () => {
        console.log("clicked!!");
    };

    return (
        <div>
            <Container component="main" maxWidth="xs">
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
            </Container>
        </div>
    )
}
export default SavingsDeposit

